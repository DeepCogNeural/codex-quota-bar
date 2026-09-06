# Local acceptance — 2026-09-06

Scope: CodexBar 0.56.7 on Apple Silicon macOS, existing Subrouter 0.1.130 with two authenticated accounts.

Performed with user authorization:

- Bundled CodexBarCLI `plugins list`: discovered and parsed the Subrouter plugin.
- Standard CodexBar approval sheet: reviewed unauthenticated loopback origin and typed it for approval. No approval file was fabricated.
- Bundled CodexBarCLI `plugins fetch subrouter`: exited successfully with separate short/weekly quota rows for two accounts.
- macOS accessibility readback of the CodexBar menu: both aliases, plan labels, remaining percentages and reset timestamps appeared.
- General settings: Language was System and the interface displayed English.

No model request, credit redemption, exhaustion/failover experiment or router change was part of these checks. No automated parser regression suite has been run. The reusable installation procedure has not been exercised on a clean second Mac.

Screen Recording permission was unavailable. There is no pixel-level screenshot acceptance; assets/overview.svg is an architectural illustration, not a screenshot. Widget integration was not tested because it is not implemented.

This establishes a local experimental menu integration, not universal compatibility or production reliability.
