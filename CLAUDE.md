# CLAUDE.md

`WWW::VastAI` — a Moo client for the Vast.ai REST APIs, released to CPAN with
`[@Author::GETTY]`.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
the principle, the lane definition and the hazards are in
`.claude/rules/www-vastai-rules.md` (auto-loaded every turn).

| Task | Agent |
|---|---|
| Implement / refactor / debug / test the client, `API::*` controllers, entities, operation map, HTTP/IO roles, inline POD | `www-vastai-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `www-vastai-release-manager` |

The agents carry their knowledge via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading those skills. Skill sources live under
`.claude/skills/` — architecture in `www-vastai-core`, the Vast.ai wire protocol in
`vastai-general`, Moo and `[@Author::GETTY]` conventions in the shared Perl skills. Work is
coordinated on the repo's own `karr` board.
