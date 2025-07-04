package errors

import (
	"encoding/json"
	"net/http"
)

type Error struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
	Details string `json:"details,omitempty"`
}

func (e *Error) Error() string {
	return e.Message
}

func New(code int, message string) *Error {
	return &Error{
		Code:    code,
		Message: message,
	}
}

func (e *Error) WithDetails(details string) *Error {
	e.Details = details
	return e
}

var (
	ErrBadRequest         = New(http.StatusBadRequest, "Bad request")
	ErrUnauthorized       = New(http.StatusUnauthorized, "Unauthorized")
	ErrForbidden          = New(http.StatusForbidden, "Forbidden")
	ErrNotFound           = New(http.StatusNotFound, "Not found")
	ErrInternalServer     = New(http.StatusInternalServerError, "Internal server error")
	ErrUserAlreadyExists  = New(http.StatusConflict, "User already exists")
	ErrInvalidCredentials = New(http.StatusUnauthorized, "Invalid credentials")
	ErrAlreadyExists      = New(http.StatusConflict, "Already exists")

	ErrWSUnauthorized = New(4401, "WebSocket unauthorized")
	ErrWSBadRequest   = New(4400, "WebSocket bad request")
	ErrWSInternal     = New(4500, "WebSocket internal error")
)

func WriteError(w http.ResponseWriter, err error) {
	var apiErr *Error
	if e, ok := err.(*Error); ok {
		apiErr = e
	} else {
		apiErr = ErrInternalServer.WithDetails(err.Error())
	}
	json.NewEncoder(w).Encode(apiErr)
}

func WriteWSError(conn interface{ WriteJSON(v interface{}) error }, err error) {
	var apiErr *Error
	if e, ok := err.(*Error); ok {
		apiErr = e
	} else {
		apiErr = ErrWSInternal.WithDetails(err.Error())
	}
	_ = conn.WriteJSON(apiErr)
}
