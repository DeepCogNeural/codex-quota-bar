package proxy

import (
	"testing"

	"github.com/manaflow-ai/subrouter/internal/accounts"
)

func TestPreferredCodexCatalogAccountID(t *testing.T) {
	status := func(id, plan string, valid bool) AccountUsageStatus {
		return AccountUsageStatus{
			AccountStatus: AccountStatus{
				ID:          id,
				Provider:    accounts.ProviderCodex,
				AuthMode:    accounts.AuthModeOAuth,
				AuthChecked: true,
				AuthValid:   valid,
			},
			PlanType: plan,
		}
	}

	tests := []struct {
		name     string
		statuses []AccountUsageStatus
		want     string
	}{
		{
			name: "valid Pro outranks EDU and Plus",
			statuses: []AccountUsageStatus{
				status("school@example.com", "edu", true),
				status("plus@example.com", "plus", true),
				status("pro@example.com", "pro", true),
			},
			want: "pro@example.com",
		},
		{
			name: "invalid Pro falls back to Plus",
			statuses: []AccountUsageStatus{
				status("pro@example.com", "pro", false),
				status("school@example.com", "edu", true),
				status("plus@example.com", "plus", true),
			},
			want: "plus@example.com",
		},
		{
			name: "same tier is stable by account ID",
			statuses: []AccountUsageStatus{
				status("z@example.com", "pro", true),
				status("a@example.com", "pro", true),
			},
			want: "a@example.com",
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if got := preferredCodexCatalogAccountID(test.statuses); got != test.want {
				t.Fatalf("preferred account = %q, want %q", got, test.want)
			}
		})
	}
}
