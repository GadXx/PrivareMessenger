package user

import (
	"encoding/json"
	"errors"
	"net/http"
	apierrors "privatemessenger/internal/errors"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/go-playground/validator/v10"
)

type UserHandler struct {
	UserService *UserService
}

func NewUserHandler(us *UserService) *UserHandler {
	return &UserHandler{us}
}

type RegisterRequest struct {
	Username           string `json:"username" validate:"required"`
	Login              string `json:"login" validate:"required"`
	IdentityKeyEd25519 string `json:"identity_key_ed25519" validate:"required"`
	IdentityKeyX25519  string `json:"identity_key_x25519" validate:"required"`
	SignedPreKey       string `json:"signed_pre_key" validate:"required"`
	SignedPreKeyId     string `json:"signed_pre_key_id" validate:"required"`
	SignedPreKeySig    string `json:"signed_pre_key_sig" validate:"required"`
	RegistrationId     string `json:"registration_id" validate:"required"`
}

func (h *UserHandler) ReservLogin(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Login       string `json:"login"`
		IdentityKey string `json:"identity_key"`
	}
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&req); err != nil {
		apierrors.WriteError(w, apierrors.ErrBadRequest.WithDetails("Invalid request body: "+err.Error()))
		return
	}

	err := h.UserService.ReservLogin(r.Context(), req.Login, req.IdentityKey)
	if err != nil {
		switch {
		case errors.Is(err, ErrUserAlreadyExists):
			apierrors.WriteError(w, apierrors.ErrUserAlreadyExists.WithDetails("User already exists"))
		default:
			apierrors.WriteError(w, apierrors.ErrInternalServer.WithDetails(err.Error()))
		}
		return
	}
	w.WriteHeader(http.StatusCreated)
}

func (h *UserHandler) Register(w http.ResponseWriter, r *http.Request) {
	var req RegisterRequest

	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&req); err != nil {
		apierrors.WriteError(w, apierrors.ErrBadRequest.WithDetails("Invalid request body: "+err.Error()))
		return
	}

	validate := validator.New()
	if err := validate.Struct(req); err != nil {
		apierrors.WriteError(w, apierrors.ErrBadRequest.WithDetails("Validation failed: "+err.Error()))
		return
	}

	user, err := h.UserService.Register(
		r.Context(),
		req.Username, req.Login, req.IdentityKeyEd25519, req.IdentityKeyX25519, req.SignedPreKey, req.SignedPreKeySig, req.SignedPreKeyId, req.RegistrationId,
	)
	if err != nil {
		if strings.Contains(err.Error(), "E11000 duplicate key error") {
			apierrors.WriteError(w, apierrors.ErrAlreadyExists.WithDetails("Login already exists"))
		} else if err.Error() == "login is not reserved" {
			apierrors.WriteError(w, apierrors.ErrBadRequest.WithDetails("Login is not reserved"))
		} else {
			apierrors.WriteError(w, apierrors.ErrInternalServer.WithDetails(err.Error()))
		}
		return
	}
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"user_id": user.ID,
	})
}

func (h *UserHandler) GetUserByLogin(w http.ResponseWriter, r *http.Request) {
	login := chi.URLParam(r, "login")
	if login == "" {
		apierrors.WriteError(w, apierrors.ErrBadRequest.WithDetails("Login parameter is required"))
		return
	}

	user, err := h.UserService.SearchUserByLogin(r.Context(), login)
	if err != nil {
		switch {
		case errors.Is(err, ErrUserNotFound):
			apierrors.WriteError(w, apierrors.ErrNotFound.WithDetails("User not found"))
		default:
			apierrors.WriteError(w, apierrors.ErrInternalServer.WithDetails(err.Error()))
		}
		return
	}

	type publicUser struct {
		ID       string `json:"id"`
		Username string `json:"username"`
		Login    string `json:"login"`
	}

	resp := publicUser{
		ID:       user.ID.Hex(),
		Username: user.Username,
		Login:    user.Login,
	}

	json.NewEncoder(w).Encode(resp)
}
