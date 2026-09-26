# WWW::VastAI House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch
(same priority as `CLAUDE.md`). Subagents get their discipline from the skills
force-loaded via `briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions. When uncertain, ask rather than guess.
   Push back when a simpler approach exists. Stop when confused; name what's unclear.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative.
3. **Surgical changes** — Touch only what you must. Don't "improve" adjacent code or
   formatting. Match existing style.
4. **Read before you write** — Before new code, read the operation map, the controller
   you're touching, and its entity class. "Looks orthogonal" is dangerous.
5. **Tests verify intent** — A test that can't fail when the logic changes is wrong.
   Reproduce a bug before fixing it; leave a regression test behind.
6. **Fail loud** — "Done" is wrong if anything was skipped silently. "Tests pass" is
   wrong if any were skipped. Surface uncertainty, don't hide it.

## Delegation

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  code yourself — delegate to `www-vastai-worker`. Your lane: coordinate, inspect, plan,
  review diffs, run tests, edit non-behavioral prose. When in doubt,
  delegate. Why: only the `www-vastai-*` agents get their skills force-loaded via
  `briefing.skills`; you get no briefing and would touch internals with too little
  context. Specialist lanes:

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug / test the client, controllers, entities, map, roles, POD | `www-vastai-worker` (default) |
  | Commits, `Changes`, card → done, pre-release audit | `www-vastai-release-manager` |

- **You cannot spawn subagents** (you ARE a `www-vastai-*` agent): The delegation lock
  does not apply to you — implement, refactor, debug, and test per these rules.

Behavior-relevant = the client and its config, `API::*` controllers, entity classes,
`Role::OperationMap`, the HTTP/IO roles and `LWPIO`, error handling, tests, and the
inline POD that documents public API. Pure prose docs and changelog notes are not.

**Only `www-vastai-release-manager` commits.** A worker leaves a commit-ready tree and hands its card
to `review`; you then dispatch `www-vastai-release-manager` to cut the commit and close the card.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope —
don't invoke the `kanban-issues-karr-coordination` skill first, just use it. Git-native kanban;
state lives in `refs/karr/*`; this repo has its own board.

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --tags a,b --body '…'` — new ticket
- `karr move ID in-progress --claim NAME` — start · `karr handoff ID --claim NAME --note "…"` — to review
- mutating commands auto-sync; `karr sync --pull|--push` for explicit exchange

**Serialize board mutations when fanning out.** Keep implementation parallel if you
like, but collect results and then loop `karr move`/`handoff`/`sync` sequentially — N of
them landing at once is a resource event, not a cheap command.

## Release — never without permission

`prove -l t/`, `dzil test`, `dzil build` are fine anytime. `dzil release` and any
upload/deploy are STRICTLY forbidden without the maintainer's explicit go-ahead — even
if a plan or STATUS document lists "release" as the next step. Stop and ask.

**CPAN state is never a blocker.** A dependency not yet on CPAN does not block anything
and is not a ticket — this author releases everything together; only the local state
counts.

## Project-specific hazards

- **Live tests cost real money.** `t/91-live-vastai-cost.t` and
  `t/92-live-vastai-volume.t` create and destroy real Vast.ai instances/volumes when run
  with `VAST_LIVE_TEST=1 VAST_LIVE_ALLOW_COST=1`. The naive "run the whole suite" looks
  harmless because `prove -l t/` skips them silently without the env vars. Never set
  `VAST_LIVE_ALLOW_COST=1`; run only `prove -l t/` unless the maintainer asks for a live
  run.
- **Routes have one home.** A URL hardcoded in an `API::*` controller instead of added
  to `Role::OperationMap::_build_operation_map` will work in a quick test and rot the
  moment a base URL or path convention changes. Every endpoint is a row in the map.

## Perl / Moo / release specifics — reference, don't restate

Moo class and role patterns live in skill `getty-perl-moo`; the distribution's own
architecture in `www-vastai-core`; the Vast.ai wire protocol in `vastai-general`; POD, `$VERSION`
and `[@Author::GETTY]` conventions in `getty-perl-release-author-getty` — all force-loaded
for `www-vastai-*` agents. Do not duplicate that content here.
