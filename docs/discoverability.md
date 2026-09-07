# Discovery and distribution

## Public entry points

- Product site: https://codex-quota-bar.sheyajane.chatgpt.site/
- Repository: https://github.com/DeepCogNeural/codex-quota-bar
- Agent-readable repository facts: https://raw.githubusercontent.com/DeepCogNeural/codex-quota-bar/main/llms.txt
- Native installation: https://github.com/DeepCogNeural/codex-quota-bar/blob/main/integrations/README.md
- Maintainer profile: https://github.com/DeepCogNeural

The site is public and includes an interactive illustration with fictional data, clear installation paths, bilingual explanatory content, software metadata, a canonical URL, robots.txt, sitemap.xml and llms.txt. None of these guarantees ranking or recommendation. The maintainer profile and v0.1.0 release link to the site. Stars are voluntary; no artificial traffic or stars are used.

## Observations — 2026-09-07

- Exact-name web searches returned other projects with a similar name; this repository was not found in the returned results. This is a sampled search, not a complete Google/Bing index audit.
- Initial GitHub API baseline: 0 stars, 0 forks, 0 reported views and clones over the previous 14 days. Traffic reporting can lag and these figures are not a user-adoption measurement.
- Public deployment succeeded. curl fetched the homepage, robots.txt, sitemap.xml, llms.txt and IndexNow ownership file successfully with HTTP 200, without account authentication.
- HTML parsing, JSON-LD parsing and sitemap XML checks passed. No browser interaction acceptance was claimed for the web illustration.
- IndexNow submission returned HTTP 202: URL received, ownership-key validation pending. This does not prove indexing. See https://www.indexnow.org/documentation .
- Python urllib received HTTP 403 on the site; a search-tool direct open was rejected. Hosting-layer bot handling and new-domain tool restrictions remain limitations. Repository and raw-text URLs provide alternate agent entry points; universal crawler access is not established.
- No authenticated Google Search Console or Bing Webmaster property was configured. Google indexing, individual search-engine rankings and AI recommendation placement remain unknown.

## Measure real adoption

Run `python3 scripts/discovery-metrics.py` with GitHub repository traffic access to read timestamped star/fork counters and 14-day views/clones. The script reports unavailable data explicitly. Store snapshots locally; do not interpret a single change as causal evidence of this page.

Compare the same query and locale over time: `Codex Quota Bar DeepCogNeural`, `Subrouter CodexBar multi account`, and `Codex Plus Pro quota macOS`. Record query, date, search engine and actual result URL. Search rank depends on engine and context; do not report one engine as all engines.

## Short public description

Codex Quota Bar connects CodexBar with Subrouter to show multiple Codex subscriptions in a compact macOS interface. Install the read-only JavaScript provider or build the optional native integration for progress bars and manual new-chat account selection. Existing conversations retain their router assignments. MIT licensed; no signed native binary is distributed.

This description is ready for a relevant community post. An X introduction was published on 2026-09-07; see the distribution ledger below. No unsolicited issues or promotional pull requests have been sent. Placement in third-party directories and communities is not an implemented feature and may require their maintainers' approval.


## Distribution goal and ledger — 2026-09-07

Goal: reach relevant users and earn at least one genuine voluntary GitHub star. A posted link, an impression, a visit, an installation and a star are distinct outcomes. Current observed star count: 0. No deadline or ranking guarantee is implied.

- Published X introduction: https://x.com/RichardRich_11/status/2097104546644324658 . X confirmed publication and displayed the exact post. The account is protected, so this is follower-only distribution, not a public-search backlink. Do not change account privacy without explicit approval; it affects historical posts too.
- Hacker News submission requires login. The approved channel is a Show HN linking directly to runnable source/install instructions, not merely the landing page. Follow https://news.ycombinator.com/showhn.html ; do not solicit votes.
- CodexBar and Subrouter both have GitHub Discussions disabled. Do not use bug reports as advertising.
- Google Search Console currently requires Google login. Next: establish a URL-prefix property for the public site, deploy its issued ownership verification, then submit sitemap and inspect the live URL. No ownership verification or indexing request has yet been completed there.

Prepared Show HN title: **Show HN: Codex Quota Bar – Multiple Codex accounts in a macOS quota UI**

Prepared first comment: I built this integration to make multiple Codex subscriptions easier to inspect on macOS. It connects CodexBar and Subrouter, with a read-only JavaScript provider and an optional native build for quota bars, 5-hour/weekly views and new-chat account selection. Existing conversations retain their routing assignments. It requires setup and has no signed native binary yet. I would especially appreciate feedback on installation friction and quota-window clarity. Credit to both upstream projects; the integration is MIT licensed.

Sequence: public targeted launch → Google ownership/index inspection → fix any concrete crawl error → collect installation feedback → measure genuine stars. Do not repeat promotional posts merely because a star has not arrived.

## Hosting explained

The product site is publicly hosted on Sites at the URL above. It serves static HTML/CSS/JavaScript from `out/`; it is independent of the maintainer's Mac. This site is a presentation and installation entry point, not the local routing service. No model API key, account login database or router endpoint is configured in the site. Underlying physical server location and billing/usage limits have not been established; do not promise permanent free hosting. Extra servers and databases are unnecessary for the current presentation site.

Google's crawl/index requirements: https://developers.google.com/search/docs/essentials/technical . An HTTP error from one client does not prove Googlebot is blocked. Search Console's live inspection is the next evidence source. `llms.txt` is a convenience for readers, not a priority-ranking contract.


### Community directory submission

2026-09-07: submitted https://github.com/RoggeOhta/awesome-codex-cli/issues/245 under the directory's explicit resource-suggestion workflow in CONTRIBUTING.md. The submission discloses maintainer affiliation, early-stage status, desktop focus, upstream dependencies and lack of a signed native binary. GitHub readback confirmed OPEN. This is a pending suggestion, not accepted inclusion. Star count at submission remained 0.

The owner prefers to keep the existing X account private; public X distribution is deferred, and no privacy settings will be changed. Prioritize relevant directories and search ownership verification.


### Google Search Console configured — 2026-09-07

Used the owner's authorized existing Chrome login. Added the URL-prefix property for https://codex-quota-bar.sheyajane.chatgpt.site/ and deployed the Google-issued HTML meta verification tag as Sites version 3, source commit 81541d9a75f1d4607cf629165988b650161f6f28. Deployment succeeded; Search Console explicitly confirmed ownership verification via HTML tag.

Submitted sitemap.xml: Search Console reported success, read on September 7, with 1 discovered page and 0 videos. URL Inspection reported “Discovered - currently not indexed”; no previous crawl data was available. The manual indexing request was rejected with “Quota exceeded” and an instruction to try tomorrow. Do not claim indexing requested successfully or bypass the quota with another account. Sitemap discovery remains valid independently of this rejected manual request.

This supersedes earlier notes saying no Google property was configured. Google successfully accessed the ownership tag and sitemap; this does not prove every crawler can fetch every route or establish homepage indexing. HN still requires login in Chrome; X remains private.


### HN account and submission outcome — 2026-09-07

Created the owner-authorized DeepCogNeural account and reached the authenticated submission form. Submitted only the existing project name (with Show HN prefix) and repository URL, without generated comments. HN returned an explicit temporary Show HN restriction for new users; no published item was confirmed. Do not remove the prefix to evade the restriction or create another account.

Credentials were retained privately outside the repository. Browser security policy blocked access to Chrome Password Manager, so browser password saving and biometric autofill remain incomplete. No credential is included in this record.

The earlier prepared first-comment draft is not for automated posting: HN's current guidelines disallow generated or AI-edited comments (https://news.ycombinator.com/newsguidelines.html). Future community participation must respect this rule and must not manufacture engagement merely to unlock promotion.
