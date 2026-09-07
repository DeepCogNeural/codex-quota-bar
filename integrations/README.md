# Native menu and manual routing integration

This opt-in source integration adds two text-free quota bars and a new-chat routing selector to CodexBar. It is separate from the released JavaScript plugin. The native application is installed and its menu has been exercised locally. The router replacement is activated locally; both account selections and returning to automatic mode were exercised through the authenticated control endpoint.

## Display contract

Two stacked 34-point tracks, 5 points tall, within a 44-point menu item. Gray translucent tracks and pale outlines remain visible at zero. Filled width indicates remaining capacity. Colors: below 20 red; 20..<50 yellow; 50..<80 green; 80...100 white. No icon text. The minimum remaining base quota window represents each account; missing or invalid data has no fill. The menu contains identity and explanatory text.

Accounts sort by plan: Pro 20x, Pro, Plus, then unknown. Within the same plan, local `quotaBarAccountOrder` preferences and then email provide stable ordering. A manual selection adds a checkmark without moving rows. In quota-only mode, the status item opens a native macOS panel containing an NSPopUpButton account selector. This keeps interactive controls outside NSMenu tracking. Clicking elsewhere closes the panel. Existing provider menus remain available when other providers are enabled. The server currently reports generic Pro for some subscriptions; the UI does not invent a 20x label. Account aliases and identifiers are not embedded in source.

## Control contract

Automatic or a manually selected account, for new Codex sessions only. Previously assigned sessions retain normal routing. Sessions first created in manual mode retain a strict pin, including after router restart or changing the default back to automatic. The existing forced-account route prevents automatic failover for pinned requests. Explicit request selectors and session leases take precedence. Model catalog requests are excluded.

The local GET/POST routing-policy handler requires a dedicated token, loopback peer, and no browser Origin. No new behavior is enabled unless both `SUBROUTER_ROUTING_POLICY_FILE` and `SUBROUTER_ROUTING_TOKEN_FILE` are configured. The token must contain at least 32 characters. Policy writes are atomic and preserve existing pins. A 10,000-session cap fails explicitly instead of discarding old pins. File failures must not silently turn manual mode into automatic mode.

UI opt-in preferences: `quotaBarEnabled`, `quotaBarTokenFile`, `quotaBarAccountOrder`, `quotaBarAliases`. Preferences are local and are never included in this repository.

## Source application

`apply.py --codexbar PATH --subrouter PATH` applies checked insertion points and copies the two source modules. It does not build, run or install anything. Source points were taken from the revisions listed below; changed insertion points are rejected before writes. Existing released plugin documentation remains the authority for v0.1.0.

## Deployment status

The owner authorized compilation, local UI checks, simulated routing checks and publishing on 2026-09-06. The native CodexBar build is installed locally. Its two account rows and native settings menu were read back, including after opening the menu. The old RouterBar LaunchAgent was stopped and archived. Original app and router launch configuration were backed up. Automatic CodexBar updates are disabled for this local modified build to prevent overwrite.

The owner subsequently authorized the service restart. The replacement binary is active with both policy/token paths configured. Authenticated manual selection of each of the two local accounts was saved and independently read back, then the default was restored to automatic. The native menu now displays the new-chat/manual-session explanation instead of the unavailable message. This is a source integration, not a signed public native binary release.

A backend rollout must add the two policy/token environment paths, preserve account and session state, restart the service, verify health/readiness and round-trip automatic/manual selection, then leave the default automatic. Keep the original launch configuration for rollback. No model request is necessary for these administrative checks.

## Reproducible build inputs

- CodexBar source: `0be7714904c311b6349a250407ad88f0ba73c524` (MIT).
- Subrouter source: release `v0.1.130` (MIT), from the existing source archive.
- Apple Swift 6.3.3, macOS arm64 Command Line Tools.
- With Command Line Tools alone, resolve SwiftPM dependencies and run `python3 integrations/prepare-clt.py CODEXBAR_PATH` before building. This excludes three editor-only KeyboardShortcuts previews and expands two SwiftUI environment macros into ordinary EnvironmentKey declarations. Full Xcode does not need this step.
- `python3 integrations/apply.py --codexbar CODEXBAR_PATH --subrouter SUBROUTER_PATH`
- Build CodexBar with `swift build -c release --product CodexBar` in its checkout.
- Copy `integrations/subrouter/quota_bar_policy_test.go` into `internal/proxy/` in the Subrouter checkout, then run `go test ./internal/proxy -run '^TestQuotaBar' -count=1` and `go build -o subrouter-quota-bar ./cmd/subrouter`.
- `QuotaBarChecks.swift` is a standalone fixture executable, not an application source file. Compile it with `QuotaBar.swift`, AppKit and SwiftUI to exercise display semantics.

## Scope

The native integration requires a locally built CodexBar and router. The v0.1.0 JavaScript download alone does not enable manual routing or menu-bar progress graphics. This repository provides original integration sources and checked insertion points, not upstream binaries. Preserve upstream licenses in derived application distributions. Do not use the source applier against unknown versions without resolving changed insertion points.

The separate `b-nnett/codex-subscription-router` project patches a copy of the desktop app. Its bottom-left subscription menu is a different integration and is not included here. Router-account widgets remain unimplemented. Native provider settings for Claude and Antigravity remain available, with their own authentication requirements.

## Acceptance record — 2026-09-06

- `go test ./internal/proxy -run '^TestQuotaBar' -count=1`: passed. Checks existing sessions, persistent manual pins after returning to automatic, explicit-selector precedence, corrupt-state rejection, control authentication, remote/browser rejection, and manual/automatic POST validation.
- `go build ... ./cmd/subrouter`: passed.
- Standalone Swift display checks: passed. Pro precedes Plus; the most constrained base window is used; thresholds 19/20/49/50/79/80/100 match the requested colors; unknown quota stays unavailable; the 36×18 image renders.
- CodexBar release build: passed after the documented CLT adaptations. Local ad-hoc signature verification passed.
- Installed native menu: accessibility readback found the two real accounts, plan labels, remaining quota and local estimated reset dates; language followed macOS English. Screenshot-level acceptance is not claimed.
- Live administrative control: both manual account selections passed POST/GET readback after the authorized restart; the final default is automatic. Native menu readback confirms that manual controls are available. No live model requests or actual quota-exhaustion failover were tested.

## Local app packaging

Preserve the original CodexBar app before replacement. A local build needs its SwiftPM resource bundles in `Contents/Resources`, the matching Sparkle framework in `Contents/Frameworks`, and the `@executable_path/../Frameworks` runtime search path. Sign and verify the complete local bundle after replacement. The acceptance build used ad-hoc signing for personal installation and retained the original helper/widget files; it is not a signed or notarized public distribution. Restoring the original app and setting `quotaBarEnabled` to false removes the native view without changing router accounts.

### Native menu interaction correction

The earlier deployment checked backend policy writes and visible menu text, but missed pointer interaction with the embedded SwiftUI Menu. That dropdown could not be activated. It has been replaced by ordinary AppKit menu actions. The replacement build and ad-hoc signature check passed. With explicit owner approval, accessibility clicks on each of the two account items and Automatic were followed by authenticated GET readback of the router policy; all three matched, and Automatic was left selected. The router was not restarted and no model request was sent for this check.

### Dropdown button acceptance — 2026-09-06

The account button is restored in a native panel anchored below the status item. The earlier hosted menu and NSPopover attempts did not pass interaction acceptance. The final release build and local bundle signature check passed. Computer Use clicked the dropdown and selected each of the two account choices and Automatic; authenticated router readback matched all three choices. Automatic was left selected. No model requests were sent and the router was not restarted.

Quota mode skips the upstream WidgetKit snapshot writer, shared-default resolver and app-group migration. The local ad-hoc build previously triggered repeated App Data permission requests for the upstream widget snapshot after its signature changed. Router widgets remain unsupported; this change avoids that unused app-group path rather than requesting broader access. Future upstream versions and signed distributions require their own compatibility checks.
