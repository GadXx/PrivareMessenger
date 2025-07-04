package middleware

import (
	"net/http"
	"privatemessenger/internal/errors"
)

func ErrorHandler(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				errors.WriteError(w, errors.ErrInternalServer.WithDetails("panic: "+toString(err)))
			}
		}()
		next.ServeHTTP(w, r)
	})
}

func toString(e interface{}) string {
	switch v := e.(type) {
	case string:
		return v
	case error:
		return v.Error()
	default:
		return "unknown error"
	}
}
