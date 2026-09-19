package proxy

import (
	"context"
	"strings"

	"github.com/manaflow-ai/subrouter/internal/accounts"
)

// codexModelCatalogAccountID chooses the credential used only to discover the
// global Codex model catalog. Catalog visibility follows the querying account,
// so a narrower EDU catalog must not hide models available through a valid Pro
// account. This is deliberately independent of response-session routing,
// scheduler headroom and the Quota Bar manual new-chat policy.
func (s Server) codexModelCatalogAccountID(ctx context.Context) string {
	if s.AccountRef == nil {
		// Hosted broker and static-test configurations do not expose local plan
		// status. Preserve their existing OAuth selection instead of guessing.
		return ""
	}
	return preferredCodexCatalogAccountID(s.AccountRef.UsageStatuses(ctx))
}

func preferredCodexCatalogAccountID(statuses []AccountUsageStatus) string {
	bestID := ""
	bestRank := -1
	for _, status := range statuses {
		if (status.Provider != "" && status.Provider != accounts.ProviderCodex) ||
			status.AuthMode != accounts.AuthModeOAuth ||
			!status.AuthChecked || !status.AuthValid || strings.TrimSpace(status.ID) == "" {
			continue
		}
		rank := codexCatalogPlanRank(status.PlanType)
		if rank > bestRank || (rank == bestRank && (bestID == "" || status.ID < bestID)) {
			bestID = status.ID
			bestRank = rank
		}
	}
	return bestID
}

func codexCatalogPlanRank(plan string) int {
	normalized := strings.ToLower(strings.TrimSpace(plan))
	switch {
	case strings.Contains(normalized, "pro"):
		return 400
	case strings.Contains(normalized, "plus"):
		return 300
	case strings.Contains(normalized, "team"),
		strings.Contains(normalized, "business"),
		strings.Contains(normalized, "enterprise"),
		strings.Contains(normalized, "edu"):
		return 200
	default:
		return 100
	}
}
