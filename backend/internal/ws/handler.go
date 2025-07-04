package ws

import (
	"context"
	"encoding/json"
	"log"
	"net/http"

	"privatemessenger/internal/auth"
	apierrors "privatemessenger/internal/errors"
	"privatemessenger/internal/key"
	"privatemessenger/internal/message"

	"github.com/gorilla/websocket"
)

type WebSocketHandler struct {
	AuthService    *auth.AuthService
	KeyService     *key.KeyService
	MessageService *message.MessageService
	Hub            *Hub
}

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

func (h *WebSocketHandler) HandleWS(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		apierrors.WriteWSError(conn, apierrors.ErrWSInternal.WithDetails("WebSocket upgrade failed: "+err.Error()))
		return
	}
	// defer conn.Close() // теперь закрытие в Client

	// 1. Получаем auth-пакет
	_, msg, err := conn.ReadMessage()
	if err != nil {
		apierrors.WriteWSError(conn, apierrors.ErrWSBadRequest.WithDetails("Auth read error: "+err.Error()))
		return
	}
	// После чтения первого сообщения
	log.Printf("AUTH RAW: %s", string(msg))
	var auth AuthPayload
	if err := json.Unmarshal(msg, &auth); err != nil || auth.Type != "auth" {
		log.Printf("AUTH UNMARSHAL ERROR: %v, payload: %s", err, string(msg))
		apierrors.WriteWSError(conn, apierrors.ErrWSBadRequest.WithDetails("Invalid auth message"))
		conn.Close()
		return
	}
	log.Printf("AUTH PAYLOAD: %+v", auth)
	// 2. Проверяем подпись
	if err := h.AuthService.Authenticate(auth.IdentityKey, auth.Nonce, auth.Signature); err != nil {
		log.Printf("AUTH ERROR: %v", err)
		apierrors.WriteWSError(conn, apierrors.ErrWSUnauthorized.WithDetails("Auth failed: "+err.Error()))
		conn.Close()
		return
	}
	IdentityKey := auth.IdentityKey
	log.Printf("✅ 1: %s", IdentityKey)

	// --- Создаём клиента и сохраняем в Hub ---
	client := NewClient(IdentityKey, conn, h.Hub)
	h.Hub.AddClient(IdentityKey, client)
	log.Printf("✅ 2: %s", IdentityKey)

	ctx := r.Context()
	// 3. Отдаём недоставленные сообщения через канал
	log.Printf("Перед DeliverUndelivered")
	msgs, err := h.MessageService.DeliverUndelivered(ctx, IdentityKey)
	if err != nil {
		log.Printf("DeliverUndelivered ERROR: %v", err)
		apierrors.WriteWSError(conn, apierrors.ErrWSInternal.WithDetails("Failed to load messages: "+err.Error()))
		return
	}
	log.Printf("✅ 3: %s", IdentityKey)
	go func() {
		for _, m := range msgs {
			bytes, _ := json.Marshal(m)
			client.Send <- bytes
			h.MessageService.MarkAsDelivered(ctx, m.ID.Hex())
		}
	}()

	go client.writePump()
	client.readPump(h, ctx)
}

// === HANDLE CHECK PREKEYS ===
func (h *WebSocketHandler) handleCheckPreKeys(conn *websocket.Conn, identityKey string, ctx context.Context) {
	count, err := h.KeyService.CountOneTimePreKeys(ctx, identityKey)
	if err != nil {
		apierrors.WriteWSError(conn, apierrors.ErrWSInternal.WithDetails("Count prekeys error: "+err.Error()))
		return
	}
	if count < 10 {
		needed := 20
		resp := NeedMorePreKeysPayload{
			Type:   "need_more_prekeys",
			Needed: needed,
		}
		_ = conn.WriteJSON(resp)
		return
	}
	resp := PreKeysCountPayload{
		Type:  "prekeys_count",
		Count: count,
	}
	_ = conn.WriteJSON(resp)
}

func (h *WebSocketHandler) handleAddPreKeys(conn *websocket.Conn, identityKey string, msg []byte, ctx context.Context) {
	var addPayload AddPreKeysPayload
	if err := json.Unmarshal(msg, &addPayload); err != nil {
		apierrors.WriteWSError(conn, apierrors.ErrWSBadRequest.WithDetails("Invalid add_prekeys msg: "+err.Error()))
		return
	}
	if len(addPayload.Keys) == 0 {
		apierrors.WriteWSError(conn, apierrors.ErrWSBadRequest.WithDetails("No keys provided"))
		return
	}
	if err := h.KeyService.AddOneTimePreKeys(ctx, identityKey, addPayload.Keys, addPayload.Id); err != nil {
		apierrors.WriteWSError(conn, apierrors.ErrWSInternal.WithDetails("Failed to save prekeys: "+err.Error()))
		return
	}
	count, _ := h.KeyService.CountOneTimePreKeys(ctx, identityKey)
	_ = conn.WriteJSON(PreKeysCountPayload{
		Type:  "prekeys_count",
		Count: count,
	})
}

func (h *WebSocketHandler) handleWSMessage(client *Client, msg []byte, ctx context.Context) bool {
	defer func() {
		if rec := recover(); rec != nil {
			log.Printf("Recovered in WS loop: %v", rec)
			client.Conn.Close()
		}
	}()
	log.Printf("[WS] raw msg: %s", string(msg))
	var msgType struct {
		Type string `json:"type"`
	}
	if err := json.Unmarshal(msg, &msgType); err == nil && msgType.Type != "" {
		switch msgType.Type {
		case "check_prekeys":
			h.handleCheckPreKeys(client.Conn, client.ID, ctx)
			return true
		case "add_prekeys":
			h.handleAddPreKeys(client.Conn, client.ID, msg, ctx)
			return true
		case "message":
			var incoming IncomingMessage
			if err := json.Unmarshal(msg, &incoming); err != nil {
				apierrors.WriteWSError(client.Conn, apierrors.ErrWSBadRequest.WithDetails("Invalid message payload: "+err.Error()))
				return true
			}
			message := &message.Message{
				From:         incoming.From,
				To:           incoming.ReceiverID,
				Ciphertext:   incoming.Content,
				EphemeralKey: incoming.EphemeralPub,
				PreKeyID:     incoming.OtpkID,
				Timestamp:    incoming.Timestamp,
			}
			if err := h.MessageService.SaveMessage(ctx, message); err != nil {
				apierrors.WriteWSError(client.Conn, apierrors.ErrWSInternal.WithDetails("Failed to save message: "+err.Error()))
				return true
			}
			if receiverClient, online := h.Hub.GetClient(incoming.ReceiverID); online {
				outMsg := map[string]interface{}{
					"type":          "message",
					"from":          message.From,
					"to":            message.To,
					"content":       message.Ciphertext,
					"ephemeral_pub": message.EphemeralKey,
					"otpk_id":       message.PreKeyID,
					"timestamp":     message.Timestamp,
				}
				bytes, _ := json.Marshal(outMsg)
				log.Printf("[WS] Pushing message to %s: %s", incoming.ReceiverID, string(bytes))
				receiverClient.Send <- bytes
				h.MessageService.MarkAsDelivered(ctx, message.ID.Hex())
			}
			return true
		}
	}
	return true
}
