# Current task

- Active goal: genuine project exposure and at least one voluntary GitHub star; goal remains incomplete.
- Published X introduction: https://x.com/RichardRich_11/status/2097104546644324658 . Confirmed sent, but account is protected; public X reach requires owner-selected public account or explicit privacy decision.
- GitHub stars observed: 0. No fabricated engagement.
- Sites live/public confirmed; static presentation only, local router remains on Mac.
- Google Search Console ownership verified via Chrome; sitemap success, 1 page discovered. Homepage discovered but not indexed; manual indexing request rejected by daily quota. HN account created; Show HN submission restricted for new users.
- Owner keeps X private. Public X promotion deferred. Next: Google says retry indexing tomorrow; await directory maintainer response. HN launch deferred by platform restriction; do not bypass or manufacture engagement.
- Submitted directory suggestion https://github.com/RoggeOhta/awesome-codex-cli/issues/245; readback OPEN, acceptance pending; stars still 0.
- Full evidence and prepared community copy: docs/discoverability.md.
- Completed: release build 120.56s, backup/install/signature check passed. Accessibility readback confirmed 5h and Weekly captions, percentages and reset dates switch together; restored initial 5h selection.

- Bing site verified via meta tag; sitemap Processing and homepage URL submission success (1 URL). Sites v4 live at source 34ce7bc108ee96596d536cfdb3d9cfdd32bc4e86.
- Current re-read: Google discovered/not indexed; directory open/no replies; stars 0. Password-save/Touch ID state cannot be inspected due browser security policy.

## School account integration — 2026-09-13

- Completed isolated Chrome SSO enrollment without replacing interactive Codex auth. School credentials stay local and are not included in this repository.
- Usage endpoint confirmed EDU authentication and 100% remaining in both base windows at enrollment. Native menu selected the added account; backend manual policy matched.
- Removed two-row truncation from expanded panel. Build/install/signature check passed; installed panel readback displayed all three accounts and the new selection. No model request was sent.
- Earlier invalid_state was an expired/invalid authorization session; fresh uninterrupted browser flow succeeded. Exact cause of invalidation remains unknown.

## Discovery update — 2026-09-13

- Google and Bing homepage indexing both explicitly confirmed in their URL Inspection tools. Earlier pending-index notes are historical.
- GitHub 0 stars/0 forks; 14-day traffic 4 views/2 uniques, may include owner. Directory suggestion #245 remains open without replies.
- Bing meta description length issue: shortened description to 156 characters; deployment pending. Separate outreach task owns new community promotion.

- Description source pushed at 668b6d1. Live deployment blocked: Sites connector returns sites_access_disabled (Sites not enabled for this workspace). Existing live site remains unchanged. Requires restoring access to the original Sites workspace before deployment; do not recreate or migrate silently.

## Quota panel correction — 2026-09-18
- Draft source: constrain native account selector to content width; allow explanatory text to wrap. Weekly base quota at exactly 100% used overrides 5h availability to zero and identifies weekly exhaustion/reset. Raw upstream windows remain unchanged; absent weekly data is not treated as exhausted.
- Files: integrations/codexbar/QuotaBar.swift, TASK_STATE.md. Automatic policy unchanged.
- Build/install/UI acceptance pending current authorization; do not describe installed app as fixed. Next: minimal release build and scoped quota/selector acceptance, then publish accepted change.

- Acceptance completed: release build 115.59s; scoped Swift fixture assertions passed; backup/install/ad-hoc signing and verification passed. AX selector width296 and left edge matched title; dropdown opened and selecting original account succeeded. Actual exhausted weekly account toggled to 5h showed0 plus weekly reason/reset. Restored original Weekly display and manual selection. No model requests/router restart; CUA timeout, used previously authorized AppleScript. Pixel screenshot not obtained.
- Files also updated: integrations/codexbar/QuotaBarChecks.swift, integrations/README.md. Publishing this accepted slice; Automatic strategy unchanged.

## Request-limit misclassification — 2026-09-18
- Root cause found in local router source withRequestTimeExhaustionWindows: synthetic Name=request-limit has UsedPercent100 and LimitWindowSeconds604800 even when limiting window is unspecified. UI ignored Name, mislabeling this overlay as weekly exhaustion.
- Source fix: decode Name; exclude request-limit from measured base-window selection/remaining/weekly exhaustion. Refresh when opening panel. Genuine weekly exhaustion still clamps 5h. No routing policy change.
- Modified integrations/codexbar/QuotaBar.swift; build/install and regression fixture pending current test authorization.

- Additional user-requested display rules: Pro always Weekly (including saved5h preferences), no toggle/action; selected5h reset remains first and never substituted with weekly reset. Genuine weekly-exhaustion note follows reset. Draft only, not installed; request-limit fix remains pending same build.

- Completed acceptance: scoped Swift regression executable passed request-limit exclusion, genuine weekly clamp, selected-window reset and Pro saved-preference/toggle checks. Release build passed108.35s (existing upstream deprecated screenshot API warning). Backed up, installed and signature verification passed.
- Actual installed UI: Pro click stayed Weekly and no quota-switch AX action; Plus toggled Weekly/5h with distinct correct reset captions, restored5h and existing manual selection. A genuinely exhausted weekly account retained its5h reset above explanation. No model request or router restart. Publishing four owned integration/state files.

## Pro-backed Codex model catalog — 2026-09-19
- Root cause: all client-version model catalog GETs use the synthetic `internal:codex-model-catalog` session. Its sticky assignment selected the EDU account, so the EDU-visible subset became the global Codex model list even though a valid Pro account could expose GPT-6 Astra.
- Draft source fix: catalog discovery selects a stable, authenticated Codex OAuth account by plan visibility (Pro, Plus, EDU/team/business/enterprise, other). The chosen ID is applied only to the cloned catalog request. No model slug is synthesized, and response-session stickiness, manual new-chat selection and Automatic routing are unchanged.
- Files: `integrations/subrouter/codex_model_catalog_policy.go`, `integrations/subrouter/codex_model_catalog_policy_test.go`, `integrations/apply.py`, `integrations/README.md`, `TASK_STATE.md`.
- Completed acceptance: focused catalog tests passed; the Router binary built, was backed up, replaced and restarted. Health and readiness returned `ok`. A real client-version catalog GET returned the upstream `gpt-6-astra` entry, and logs showed `internal:codex-model-catalog` move from EDU to the Pro account. The manual new-chat policy remained `manual` on the same selected account. No test response request was sent.
- Rollback: `/Users/linghao/.local/share/subrouter-trial/quota-bar-backup/before-pro-catalog-20260919/`.
- Publishing the five owned integration/state files; no credentials or local account files are included.
