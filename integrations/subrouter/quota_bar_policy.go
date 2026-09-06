package proxy

import (
	"crypto/subtle"
	"encoding/json"
	"errors"
	"io"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"github.com/manaflow-ai/subrouter/session"
)

// Opt-in local policy. No state or behavior change without both environment paths.
// Explicit request selectors and existing sessions always take precedence.
type quotaBarPolicy struct {
	Mode      string            `json:"mode"`
	AccountID string            `json:"accountID,omitempty"`
	TargetID  string            `json:"targetID,omitempty"`
	Pins      map[string]string `json:"pins,omitempty"`
}

var quotaBarLock sync.Mutex

func quotaBarPaths() (string, string) {
	return os.Getenv("SUBROUTER_ROUTING_POLICY_FILE"), os.Getenv("SUBROUTER_ROUTING_TOKEN_FILE")
}
func readQuotaBarPolicy(path string) (quotaBarPolicy, error) {
	p := quotaBarPolicy{Mode: "auto", Pins: map[string]string{}}
	data, err := os.ReadFile(path)
	if os.IsNotExist(err) {
		return p, nil
	}
	if err != nil {
		return p, err
	}
	if err = json.Unmarshal(data, &p); err != nil {
		return p, err
	}
	if p.Mode != "auto" && p.Mode != "manual" {
		return p, errors.New("invalid routing policy")
	}
	if p.Mode == "manual" && (p.AccountID == "" || p.TargetID == "") {
		return p, errors.New("missing manual account")
	}
	if p.Pins == nil {
		p.Pins = map[string]string{}
	}
	return p, nil
}
func saveQuotaBarPolicy(path string, p quotaBarPolicy) error {
	data, err := json.Marshal(p)
	if err != nil {
		return err
	}
	f, err := os.CreateTemp(filepath.Dir(path), ".routing-*")
	if err != nil {
		return err
	}
	name := f.Name()
	defer os.Remove(name)
	if _, err = f.Write(data); err == nil {
		err = f.Sync()
	}
	closeErr := f.Close()
	if err != nil {
		return err
	}
	if closeErr != nil {
		return closeErr
	}
	return os.Rename(name, path)
}
func (s Server) handleQuotaBarPolicy(w http.ResponseWriter, r *http.Request) {
	path, tokenPath := quotaBarPaths()
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	ip := net.ParseIP(host)
	if path == "" || tokenPath == "" || err != nil || ip == nil || !ip.IsLoopback() || r.Header.Get("Origin") != "" {
		http.Error(w, "local routing control unavailable", http.StatusForbidden)
		return
	}
	token, err := os.ReadFile(tokenPath)
	expected := strings.TrimSpace(string(token))
	if err != nil || len(expected) < 32 || subtle.ConstantTimeCompare([]byte(r.Header.Get("X-Quota-Bar-Token")), []byte(expected)) != 1 {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	if r.Method != http.MethodGet && r.Method != http.MethodPost {
		w.Header().Set("Allow", "GET, POST")
		http.Error(w, "method not allowed", 405)
		return
	}
	quotaBarLock.Lock()
	defer quotaBarLock.Unlock()
	p, err := readQuotaBarPolicy(path)
	if err != nil {
		http.Error(w, "cannot read routing policy", 500)
		return
	}
	if r.Method == http.MethodPost {
		var input struct {
			Mode      string `json:"mode"`
			AccountID string `json:"accountID"`
		}
		dec := json.NewDecoder(http.MaxBytesReader(w, r.Body, 2048))
		dec.DisallowUnknownFields()
		if dec.Decode(&input) != nil || dec.Decode(new(any)) != io.EOF || (input.Mode != "auto" && input.Mode != "manual") {
			http.Error(w, "invalid routing policy", 400)
			return
		}
		if input.Mode == "manual" {
			// Account IDs are resolved against the live Codex pool; no credential is returned.
			matches := 0
			target := ""
			for _, a := range s.accountListContext(r.Context()) {
				if (string(a.Provider) == "codex" || string(a.Provider) == "") && (a.ID == input.AccountID || a.Email == input.AccountID) {
					matches++
					target = a.ID
				}
			}
			if matches != 1 {
				http.Error(w, "unknown Codex account", 400)
				return
			}
			p.TargetID = target
		} else {
			input.AccountID = ""
			p.TargetID = ""
		}
		p.Mode, p.AccountID = input.Mode, input.AccountID
		if saveQuotaBarPolicy(path, p) != nil {
			http.Error(w, "cannot save routing policy", 500)
			return
		}
	}
	// Session pins are private state, not part of the UI response.
	writeJSON(w, map[string]string{"mode": p.Mode, "accountID": p.AccountID})
}
func (s Server) applyQuotaBarPolicy(r *http.Request, agent, sessionID string) error {
	path, tokenPath := quotaBarPaths()
	if path == "" || tokenPath == "" {
		return nil
	}
	_, present, err := session.ExtractAccountIDWithPresence(r)
	if err != nil || present {
		return err
	}
	if sessionID == "" {
		return errors.New("manual routing requires a session identity")
	}
	quotaBarLock.Lock()
	defer quotaBarLock.Unlock()
	p, err := readQuotaBarPolicy(path)
	if err != nil {
		return err
	}
	key := agent + "\x00" + sessionID
	pinned := p.Pins[key]
	if pinned == "" {
		if _, exists := s.Sessions.Get(agent, sessionID); exists || p.Mode == "auto" {
			return nil
		}
		// Persist the user's choice before routing. Retries and restarts keep the same pin,
		// even if the first request fails or the user later changes the new-chat default.
		if len(p.Pins) >= 10000 {
			return errors.New("manual session pin limit reached")
		}
		pinned = p.TargetID
		p.Pins[key] = pinned
		if err := saveQuotaBarPolicy(path, p); err != nil {
			return err
		}
	}
	r.Header.Set("X-Subrouter-Account-ID", pinned)
	return nil
}
