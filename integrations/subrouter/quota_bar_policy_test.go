package proxy

import (
	"github.com/manaflow-ai/subrouter/internal/accounts"
	"github.com/manaflow-ai/subrouter/session"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestQuotaBarSessionPolicy(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "policy.json")
	t.Setenv("SUBROUTER_ROUTING_POLICY_FILE", path)
	t.Setenv("SUBROUTER_ROUTING_TOKEN_FILE", filepath.Join(dir, "token"))
	store, err := session.NewStore(filepath.Join(dir, "sessions.json"))
	if err != nil {
		t.Fatal(err)
	}
	s := Server{Sessions: store}
	if _, err = store.Put("codex", "old", "original", ""); err != nil {
		t.Fatal(err)
	}
	p := quotaBarPolicy{Mode: "manual", AccountID: "fixture", TargetID: "selected", Pins: map[string]string{}}
	if err = saveQuotaBarPolicy(path, p); err != nil {
		t.Fatal(err)
	}
	check := func(id, want string) {
		t.Helper()
		r := httptest.NewRequest("POST", "http://localhost/v1/responses", nil)
		if err := s.applyQuotaBarPolicy(r, "codex", id); err != nil {
			t.Fatal(err)
		}
		if got := r.Header.Get("X-Subrouter-Account-ID"); got != want {
			t.Fatalf("%s: got %q want %q", id, got, want)
		}
	}
	check("old", "")
	check("new", "selected")
	p, err = readQuotaBarPolicy(path)
	if err != nil {
		t.Fatal(err)
	}
	p.Mode = "auto"
	p.AccountID = ""
	p.TargetID = ""
	if err = saveQuotaBarPolicy(path, p); err != nil {
		t.Fatal(err)
	}
	check("new", "selected")
	check("automatic", "")
	r := httptest.NewRequest("POST", "http://localhost/v1/responses", nil)
	r.Header.Set("X-Subrouter-Account-ID", "explicit")
	if err = s.applyQuotaBarPolicy(r, "codex", "new"); err != nil {
		t.Fatal(err)
	}
	if r.Header.Get("X-Subrouter-Account-ID") != "explicit" {
		t.Fatal("explicit selector lost")
	}
	if err = os.WriteFile(path, []byte("invalid"), 0600); err != nil {
		t.Fatal(err)
	}
	r = httptest.NewRequest("POST", "http://localhost/v1/responses", nil)
	if s.applyQuotaBarPolicy(r, "codex", "other") == nil {
		t.Fatal("corruption silently enabled auto")
	}
}

func TestQuotaBarControlAuthorization(t *testing.T) {
	dir := t.TempDir()
	token := strings.Repeat("x", 40)
	tokenPath := filepath.Join(dir, "token")
	if err := os.WriteFile(tokenPath, []byte(token), 0600); err != nil {
		t.Fatal(err)
	}
	t.Setenv("SUBROUTER_ROUTING_POLICY_FILE", filepath.Join(dir, "policy"))
	t.Setenv("SUBROUTER_ROUTING_TOKEN_FILE", tokenPath)
	for _, tc := range []struct {
		name, remote, token, origin string
		want                        int
	}{
		{"valid", "127.0.0.1:1234", token, "", 200},
		{"missing", "127.0.0.1:1234", "", "", 401},
		{"remote", "192.0.2.1:1234", token, "", 403},
		{"browser", "127.0.0.1:1234", token, "http://localhost", 403},
	} {
		t.Run(tc.name, func(t *testing.T) {
			r := httptest.NewRequest("GET", "http://localhost/_subrouter/routing-policy", nil)
			r.RemoteAddr = tc.remote
			r.Header.Set("X-Quota-Bar-Token", tc.token)
			r.Header.Set("Origin", tc.origin)
			w := httptest.NewRecorder()
			(Server{}).handleQuotaBarPolicy(w, r)
			if w.Code != tc.want {
				t.Fatalf("got %d want %d", w.Code, tc.want)
			}
		})
	}
}

func TestQuotaBarManualSelectionAPI(t *testing.T) {
	dir := t.TempDir()
	token := strings.Repeat("t", 40)
	tokenPath := filepath.Join(dir, "token")
	if err := os.WriteFile(tokenPath, []byte(token), 0600); err != nil {
		t.Fatal(err)
	}
	t.Setenv("SUBROUTER_ROUTING_POLICY_FILE", filepath.Join(dir, "policy"))
	t.Setenv("SUBROUTER_ROUTING_TOKEN_FILE", tokenPath)
	s := Server{Accounts: []accounts.Account{{ID: "canonical", Email: "fixture@example.com", Provider: accounts.ProviderCodex}}}
	for _, tc := range []struct {
		body string
		want int
	}{
		{`{"mode":"manual","accountID":"fixture@example.com"}`, 200},
		{`{"mode":"manual","accountID":"missing"}`, 400},
		{`{"mode":"auto"}`, 200},
		{`{"mode":"auto","pins":{}}`, 400},
	} {
		r := httptest.NewRequest("POST", "http://localhost/_subrouter/routing-policy", strings.NewReader(tc.body))
		r.RemoteAddr = "127.0.0.1:1234"
		r.Header.Set("X-Quota-Bar-Token", token)
		w := httptest.NewRecorder()
		s.handleQuotaBarPolicy(w, r)
		if w.Code != tc.want {
			t.Fatalf("%s: got %d", tc.body, w.Code)
		}
	}
}
