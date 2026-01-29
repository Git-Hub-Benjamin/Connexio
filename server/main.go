package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
)

// SyncItem represents the current synced content
type SyncItem struct {
	Type      string `json:"type"`      // "text", "image", "file"
	Content   string `json:"content"`   // text content or base64 for images
	Filename  string `json:"filename"`  // original filename
	MimeType  string `json:"mimeType"`  // MIME type
	FileID    string `json:"fileId"`    // ID for file downloads
	Timestamp string `json:"timestamp"` // ISO timestamp
}

// SavedSlot represents a saved item slot
type SavedSlot struct {
	ID      string   `json:"id"`
	Name    string   `json:"name"`
	Type    string   `json:"type"`
	SavedAt string   `json:"savedAt"`
	Preview string   `json:"preview,omitempty"`
	Item    SyncItem `json:"item"`
}

// Server holds the server state
type Server struct {
	mu          sync.RWMutex
	currentItem *SyncItem
	slots       map[string]*SavedSlot
	dataDir     string
}

func NewServer(dataDir string) *Server {
	s := &Server{
		slots:   make(map[string]*SavedSlot),
		dataDir: dataDir,
	}
	s.loadData()
	return s
}

func (s *Server) loadData() {
	// Create data directory if it doesn't exist
	os.MkdirAll(s.dataDir, 0755)
	os.MkdirAll(filepath.Join(s.dataDir, "files"), 0755)

	// Load current item
	currentPath := filepath.Join(s.dataDir, "current.json")
	if data, err := os.ReadFile(currentPath); err == nil {
		var item SyncItem
		if json.Unmarshal(data, &item) == nil {
			s.currentItem = &item
		}
	}

	// Load slots
	slotsPath := filepath.Join(s.dataDir, "slots.json")
	if data, err := os.ReadFile(slotsPath); err == nil {
		json.Unmarshal(data, &s.slots)
	}
}

func (s *Server) saveData() {
	// Save current item
	currentPath := filepath.Join(s.dataDir, "current.json")
	if s.currentItem != nil {
		data, _ := json.Marshal(s.currentItem)
		os.WriteFile(currentPath, data, 0644)
	} else {
		os.Remove(currentPath)
	}

	// Save slots
	slotsPath := filepath.Join(s.dataDir, "slots.json")
	data, _ := json.Marshal(s.slots)
	os.WriteFile(slotsPath, data, 0644)
}

// Handlers
func (s *Server) healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status": "ok",
		"time":   time.Now().Format(time.RFC3339),
	})
}

func (s *Server) getCurrentHandler(w http.ResponseWriter, r *http.Request) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	w.Header().Set("Content-Type", "application/json")
	if s.currentItem == nil {
		json.NewEncoder(w).Encode(map[string]interface{}{})
	} else {
		json.NewEncoder(w).Encode(s.currentItem)
	}
}

func (s *Server) setCurrentHandler(w http.ResponseWriter, r *http.Request) {
	var item SyncItem
	if err := json.NewDecoder(r.Body).Decode(&item); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	s.mu.Lock()
	s.currentItem = &item
	s.saveData()
	s.mu.Unlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

func (s *Server) deleteCurrentHandler(w http.ResponseWriter, r *http.Request) {
	s.mu.Lock()
	s.currentItem = nil
	s.saveData()
	s.mu.Unlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

func (s *Server) uploadHandler(w http.ResponseWriter, r *http.Request) {
	// Parse multipart form (max 100MB)
	if err := r.ParseMultipartForm(100 << 20); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	file, header, err := r.FormFile("file")
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	defer file.Close()

	// Generate file ID
	fileID := uuid.New().String()
	filePath := filepath.Join(s.dataDir, "files", fileID)

	// Save file
	out, err := os.Create(filePath)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer out.Close()

	if _, err := io.Copy(out, file); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Update current item
	s.mu.Lock()
	s.currentItem = &SyncItem{
		Type:      "file",
		Filename:  header.Filename,
		MimeType:  header.Header.Get("Content-Type"),
		FileID:    fileID,
		Timestamp: time.Now().Format(time.RFC3339),
	}
	s.saveData()
	s.mu.Unlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status": "ok",
		"fileId": fileID,
	})
}

func (s *Server) downloadHandler(w http.ResponseWriter, r *http.Request) {
	fileID := strings.TrimPrefix(r.URL.Path, "/files/")
	if fileID == "" {
		http.Error(w, "File ID required", http.StatusBadRequest)
		return
	}

	filePath := filepath.Join(s.dataDir, "files", fileID)
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		http.Error(w, "File not found", http.StatusNotFound)
		return
	}

	http.ServeFile(w, r, filePath)
}

func (s *Server) getSlotsHandler(w http.ResponseWriter, r *http.Request) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	slots := make([]*SavedSlot, 0, len(s.slots))
	for _, slot := range s.slots {
		// Don't include full item data in list
		slotCopy := *slot
		slotCopy.Item = SyncItem{}
		slots = append(slots, &slotCopy)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(slots)
}

func (s *Server) createSlotHandler(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Name string   `json:"name"`
		Item SyncItem `json:"item"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	slotID := uuid.New().String()
	preview := ""
	if req.Item.Type == "text" && len(req.Item.Content) > 0 {
		preview = req.Item.Content
		if len(preview) > 50 {
			preview = preview[:50] + "..."
		}
	}

	slot := &SavedSlot{
		ID:      slotID,
		Name:    req.Name,
		Type:    req.Item.Type,
		SavedAt: time.Now().Format(time.RFC3339),
		Preview: preview,
		Item:    req.Item,
	}

	s.mu.Lock()
	s.slots[slotID] = slot
	s.saveData()
	s.mu.Unlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status": "ok",
		"id":     slotID,
	})
}

func (s *Server) loadSlotHandler(w http.ResponseWriter, r *http.Request) {
	slotID := strings.TrimSuffix(strings.TrimPrefix(r.URL.Path, "/slots/"), "/load")

	s.mu.Lock()
	defer s.mu.Unlock()

	slot, ok := s.slots[slotID]
	if !ok {
		http.Error(w, "Slot not found", http.StatusNotFound)
		return
	}

	s.currentItem = &slot.Item
	s.saveData()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

func (s *Server) deleteSlotHandler(w http.ResponseWriter, r *http.Request) {
	slotID := strings.TrimPrefix(r.URL.Path, "/slots/")

	s.mu.Lock()
	delete(s.slots, slotID)
	s.saveData()
	s.mu.Unlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

// CORS middleware
func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func main() {
	port := flag.Int("port", 8080, "Server port")
	dataDir := flag.String("data", "./data", "Data directory")
	flag.Parse()

	server := NewServer(*dataDir)

	mux := http.NewServeMux()

	// Health check
	mux.HandleFunc("/health", server.healthHandler)

	// Current item
	mux.HandleFunc("/current", func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case "GET":
			server.getCurrentHandler(w, r)
		case "POST":
			server.setCurrentHandler(w, r)
		case "DELETE":
			server.deleteCurrentHandler(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})

	// File upload/download
	mux.HandleFunc("/upload", server.uploadHandler)
	mux.HandleFunc("/files/", server.downloadHandler)

	// Slots
	mux.HandleFunc("/slots", func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case "GET":
			server.getSlotsHandler(w, r)
		case "POST":
			server.createSlotHandler(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})
	mux.HandleFunc("/slots/", func(w http.ResponseWriter, r *http.Request) {
		if strings.HasSuffix(r.URL.Path, "/load") {
			server.loadSlotHandler(w, r)
		} else if r.Method == "DELETE" {
			server.deleteSlotHandler(w, r)
		} else {
			http.Error(w, "Not found", http.StatusNotFound)
		}
	})

	addr := fmt.Sprintf(":%d", *port)
	log.Printf("Connexio server starting on %s", addr)
	log.Printf("Data directory: %s", *dataDir)

	if err := http.ListenAndServe(addr, corsMiddleware(mux)); err != nil {
		log.Fatal(err)
	}
}
