package ws

import (
	"sync"
)

type Hub struct {
	clients map[string]*Client
	mutex   sync.RWMutex
}

func NewHub() *Hub {
	return &Hub{
		clients: make(map[string]*Client),
	}
}

func (h *Hub) AddClient(id string, client *Client) {
	h.mutex.Lock()
	h.clients[id] = client
	h.mutex.Unlock()
}

func (h *Hub) RemoveClient(id string) {
	h.mutex.Lock()
	delete(h.clients, id)
	h.mutex.Unlock()
}

func (h *Hub) GetClient(id string) (*Client, bool) {
	h.mutex.RLock()
	client, ok := h.clients[id]
	h.mutex.RUnlock()
	return client, ok
}

func (h *Hub) Broadcast(msg []byte, excludeID string) {
	h.mutex.RLock()
	for id, client := range h.clients {
		if id == excludeID {
			continue
		}
		client.Send <- msg
	}
	h.mutex.RUnlock()
}
