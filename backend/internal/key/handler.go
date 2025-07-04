package key

import (
	"encoding/json"
	"errors"
	"log"
	"net/http"
	apierrors "privatemessenger/internal/errors"

	"github.com/go-chi/chi/v5"
)

type KeyHandler struct {
	KeyService *KeyService
}

func NewKeyHandler(ks *KeyService) *KeyHandler {
	return &KeyHandler{ks}
}

func (h *KeyHandler) GetPublicKeyBundle(w http.ResponseWriter, r *http.Request) {
	UserID := chi.URLParam(r, "user_id")
	keyBundle, err := h.KeyService.GetPublicKeyBundle(r.Context(), UserID)
	if err != nil {
		switch {
		case errors.Is(err, ErrKeyBundleNotFound):
			apierrors.WriteError(w, apierrors.ErrNotFound.WithDetails("Key bundle not found"))
		default:
			apierrors.WriteError(w, apierrors.ErrInternalServer.WithDetails(err.Error()))
		}
		return
	}
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(keyBundle)
}

func (h *KeyHandler) GetOneTimePreKey(w http.ResponseWriter, r *http.Request) {
	log.Println("start")
	idk := r.URL.Query().Get("idk")
	otpk, err := h.KeyService.TakeOneTimePreKey(r.Context(), idk)
	if err != nil {
		switch {
		case errors.Is(err, ErrKeyBundleNotFound):
			apierrors.WriteError(w, apierrors.ErrNotFound.WithDetails("Key bundle not found"))
		case errors.Is(err, ErrNoOneTimeKeys):
			apierrors.WriteError(w, apierrors.ErrNotFound.WithDetails("No available one-time pre-keys"))
		default:
			apierrors.WriteError(w, apierrors.ErrInternalServer.WithDetails(err.Error()))
		}
		return
	}
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(otpk)
}

func (h *KeyHandler) CountOneTimePreKeys(w http.ResponseWriter, r *http.Request) {
	var req struct {
		UserID string `json:"user_id"`
	}
	decoder := json.NewDecoder(r.Body)
	if err := decoder.Decode(&req); err != nil {
		apierrors.WriteError(w, apierrors.ErrBadRequest.WithDetails("Invalid request body: "+err.Error()))
		return
	}
	count, err := h.KeyService.CountOneTimePreKeys(r.Context(), req.UserID)
	if err != nil {
		switch {
		case errors.Is(err, ErrKeyBundleNotFound):
			apierrors.WriteError(w, apierrors.ErrNotFound.WithDetails("Key bundle not found"))
		default:
			apierrors.WriteError(w, apierrors.ErrInternalServer.WithDetails(err.Error()))
		}
		return
	}
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"count": count,
	})
}

func (h *KeyHandler) DeleteUsedOneTimePreKey(w http.ResponseWriter, r *http.Request) {
	var req struct {
		UserID string `json:"user_id"`
	}
	decoder := json.NewDecoder(r.Body)
	if err := decoder.Decode(&req); err != nil {
		apierrors.WriteError(w, apierrors.ErrBadRequest.WithDetails("Invalid request body: "+err.Error()))
		return
	}
	err := h.KeyService.DeleteUsedOneTimePreKey(r.Context(), req.UserID)
	if err != nil {
		switch {
		case errors.Is(err, ErrKeyBundleNotFound):
			apierrors.WriteError(w, apierrors.ErrNotFound.WithDetails("Key bundle not found"))
		default:
			apierrors.WriteError(w, apierrors.ErrInternalServer.WithDetails(err.Error()))
		}
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
