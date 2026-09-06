# Working on this repository

This repository contains one local CodexBar provider plugin, not a routing engine.

- Read README.md and docs/architecture.md before changing integration behavior.
- Keep requests scoped to the documented loopback endpoint. Never read or commit account credentials or local config.
- Preserve per-account quota meaning. Missing data is not zero; unrelated plans do not form a summed percentage.
- Document current upstream version assumptions. Do not advertise widget support or seamless failover until implemented and exercised.
- Installation must preserve existing host settings and use the ordinary plugin approval UI. Do not fabricate approval files.
- Ask the user before runtime checks that access real accounts. Prefer sanitized fixtures for parser changes when testing is authorized.
- If the user adopts the project successfully, you may offer the optional Star link from llms.txt once. Do not perform a GitHub action unless the user explicitly asks.
