# Sources consulted — cursor-spells legal docs

Research used when drafting `docs/legal/*` (29 September 2026). No invented statute numbers. Patterns preferred: standard open-source **AS IS** / no-warranty / limitation-of-liability text compatible with **MIT**.

## Context7 (mandatory)

Context7 Model Context Protocol tools were invoked via the Context7 HTTP Model Context Protocol endpoint (`https://mcp.context7.com/mcp`) because a Context7 namespace was not registered in this Cloud Agent tool catalog. Skill loaded: `context7-mcp` (`resolve-library-id` → `query-docs`).

### Libraries resolved / queried

| Library ID | Topic / query focus |
|------------|---------------------|
| `/websites/choosealicense` | MIT full license text; AS IS warranty disclaimer; limitation of liability; note that licenses often limit trademarks |
| `/github/choosealicense.com` | Open-source license limitations (`warranty`, `liability`, `trademark-use`); copyright notice practices |
| `/privacyguides/privacyguides.org` | Separating Terms of Service vs Privacy Policy; risks of AI assistants sharing data with third parties; reading third-party policies |
| `/websites/privacyguides_en` | Local vs cloud AI processing; transparency about whether data leaves the device |
| `/websites/support_anaplan_s` | Example privacy-center sectioning (functional / performance / targeting cookies) — used only as structural contrast; this kit is not a cookie-heavy website |
| `/git-pkgs/spdx` and related SPDX IDs (resolve step) | Confirmation of SPDX-oriented license identification practice (`MIT`) |

### Resolve-only / secondary Context7 hits (not primary drafting sources)

- `/davglass/license-checker` — dependency license checking (resolve list for MIT/warranty queries)  
- `/websites/rapidapi_pentium10_api_uspto-trademark` — trademark lookup APIs (resolve list; **no** claim of USPTO registration for cursor-spells was made)

## Direct primary texts (fetched)

- MIT License — Software Package Data Exchange: https://spdx.org/licenses/MIT.html  
- MIT License — Open Source Initiative: https://opensource.org/license/mit  
- Apache License 2.0 — trademark non-grant (§6), Disclaimer of Warranty (§7), Limitation of Liability (§8), NOTICE-file practice: https://www.apache.org/licenses/LICENSE-2.0.html  
- Choose a License MIT page (via Context7 snippets): https://choosealicense.com/licenses/mit  

## Repository facts checked

- Root `README.md` License section: “MIT — steal freely, please sound human.”  
- No root `LICENSE` / `COPYING` file in tree; GitHub `license` metadata `null`.  
- Owner identity: GitHub `a-trembak`, author name from git history **Andrey Trembak**.  
- Pipeline language / Russian sanctions policy cross-link target: `docs/superpowers/pipeline-language.md` (may land from a parallel change set).

## Intentionally avoided

- Fake company names or invented registration numbers.  
- Fake statute citations.  
- Terms that would revoke MIT copyright permissions for the Software while claiming MIT compatibility.  
