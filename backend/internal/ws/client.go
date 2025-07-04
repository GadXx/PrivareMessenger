package ws

import (
	"context"
	"sync"

	"github.com/gorilla/websocket"
)

type Client struct {
	ID   string
	Conn *websocket.Conn
	Hub  *Hub
	Send chan []byte // канал для отправки сообщений
	once sync.Once
}

func NewClient(id string, conn *websocket.Conn, hub *Hub) *Client {
	return &Client{
		ID:   id,
		Conn: conn,
		Hub:  hub,
		Send: make(chan []byte, 32), // буфер на 32 сообщения
	}
}

func (c *Client) writePump() {
	for msg := range c.Send {
		if err := c.Conn.WriteMessage(websocket.TextMessage, msg); err != nil {
			break
		}
	}
	c.Disconnect()
}

func (c *Client) readPump(handler *WebSocketHandler, ctx context.Context) {
	for {
		_, msg, err := c.Conn.ReadMessage()
		if err != nil {
			break
		}
		handler.handleWSMessage(c, msg, ctx)
	}
	c.Disconnect()
}

func (c *Client) Disconnect() {
	c.Hub.RemoveClient(c.ID)
	c.Conn.Close()
	c.once.Do(func() {
		close(c.Send)
	})
}
