# WWW::VastAI House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Perl client for the Vast.ai REST APIs. Read first: the operation map, the controller you're
touching, and its entity class.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug / test the client, controllers, entities, map, roles, POD | `www-vastai-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `www-vastai-release-manager` |
| Read-only research, audit, gap analysis | `www-vastai-worker` ("read-only, change nothing") |

Behavior-relevant = the client and its config, `API::*` controllers, entity classes,
`Role::OperationMap`, the HTTP/IO roles and `LWPIO`, error handling, tests, and the inline POD
that documents public API. Pure prose docs and changelog notes are not.

## Hazards

- **Live tests cost real money.** `t/91-live-vastai-cost.t` and `t/92-live-vastai-volume.t`
  create and destroy real Vast.ai instances/volumes when run with `VAST_LIVE_TEST=1
  VAST_LIVE_ALLOW_COST=1`. The naive "run the whole suite" looks harmless because
  `prove -l t/` skips them silently without the env vars. Never set `VAST_LIVE_ALLOW_COST=1`;
  run only `prove -l t/` unless the maintainer asks for a live run.
- **Routes have one home.** A URL hardcoded in an `API::*` controller instead of added to
  `Role::OperationMap::_build_operation_map` will work in a quick test and rot the moment a
  base URL or path convention changes. Every endpoint is a row in the map.

## Perl / Moo / release specifics — reference, don't restate

Moo class and role patterns live in skill `getty-perl-moo`; the distribution's own
architecture in `www-vastai-core`; the Vast.ai wire protocol in `vastai-general`; POD,
`$VERSION` and `[@Author::GETTY]` conventions in `getty-perl-release-author-getty` — all
force-loaded for `www-vastai-*` agents.
