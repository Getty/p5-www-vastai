---
name: www-vastai-core
description: Architecture and invariants of WWW::VastAI — the Moo client for the Vast.ai REST APIs. Load when implementing, refactoring, debugging or testing anything in this distribution, or adding an API endpoint.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# WWW::VastAI — architecture and invariants

`WWW::VastAI` is a Moo client for the Vast.ai REST APIs. It wraps the marketplace,
instance lifecycle, templates, volumes, SSH/API keys, the current user and env
vars, invoices, and serverless endpoints/workergroups. For the wire protocol
itself (routes, bodies, operators) the `vast-ai` skill is the reference; this
skill is how *this distribution* is built.

## Layers

- **`WWW::VastAI`** — main client. Owns config (`api_key` from `$ENV{VAST_API_KEY}`,
  `console_url`, derived `base_url`/`base_url_v1`, `run_url`) and one lazy accessor
  per resource group (`offers`, `instances`, `templates`, `volumes`, `endpoints`,
  `workergroups`, `ssh_keys`, `api_keys`, `user`, `env_vars`, `invoices`). Consumes
  `Role::HTTP` and `Role::OperationMap`.
- **`API::*`** — resource controllers (`Offers`, `Instances`, `Volumes`, …). Each
  holds `client` and its methods call `request_op` and inflate payloads into entity
  objects where a stable shape exists.
- **`*.pm` entities** — value objects (`Offer`, `Instance`, `Template`, `Volume`,
  `Endpoint`, `Workergroup`, `User`, `Invoice`, `SSHKey`, `APIKey`), constructed
  from an API response hash. `Object.pm` is the shared base.
- **`Role::OperationMap`** — the single route table (`_build_operation_map`): every
  operation name → `{ method, base, path }`. `base` is one of `v0`/`v1`/`run`,
  resolved against `base_url` / `base_url_v1` / `run_url`. `{id}` (and `{ssh_key_id}`
  etc.) are path placeholders. This is the one place routes are declared — never
  hardcode a URL in a controller.
- **`Role::HTTP`** — builds the request (Bearer auth, JSON encode), dispatches
  through the IO backend, decodes the response. Verb helpers `get/post/put/delete`.
- **`Role::IO`** — the transport seam: a single required method `call($request) ->
  $response`, request/response being `WWW::VastAI::HTTPRequest` /
  `HTTPResponse`. **`LWPIO`** is the default backend (LWP::UserAgent). Swap the
  backend by passing `io => $backend` to the constructor — this is the mock seam.

Three API bases: `v0` → `console.vast.ai/api/v0`, `v1` → `console.vast.ai/api/v1`,
`run` → `run.vast.ai`.

## Adding an API endpoint

1. Add the operation to `Role::OperationMap::_build_operation_map` (`method`,
   `base`, `path` with `{id}`-style placeholders).
2. Add or extend the matching `API::*` controller method — it calls `request_op`
   (or a verb helper) and inflates the result.
3. Add an entity class only if the endpoint returns a stable object shape.
4. Add a lazy accessor on `WWW::VastAI` if this is a new resource group.
5. Add tests (mock route + assertions). Update inline POD and, if the public
   workflow changed, `README.md`.

## Testing

```bash
prove -l t/                                      # unit tests, fully mocked
VAST_LIVE_TEST=1 prove -lv t/90-live-vastai.t    # read-only live, free
VAST_LIVE_TEST=1 VAST_LIVE_ALLOW_COST=1 prove -lv t/91-*.t t/92-*.t  # COST-INCURRING
```

Unit tests never hit the network. The harness is `t/lib/Test/WWW::VastAI::Mock`,
which exports `mock_vast`:

```perl
use lib 't/lib';
use Test::WWW::VastAI::Mock;

my $vast = mock_vast(
    'POST /bundles/'   => sub { my ($method, $path, %opts) = @_; ... ; [ {...} ] },
    'PUT /asks/7001/'  => { new_contract => { id => 991, ... } },   # or a plain hash
);
```

Routes are keyed `"<METHOD> <path>"` (path with bases stripped); the value is a
coderef (gets `$method, $path, %opts` where `$opts{body}` is the decoded request
JSON), a hashref/arrayref (encoded as a 200 body), or a prebuilt
`WWW::VastAI::HTTPResponse`. Keys are matched exactly first, then as regex. Under
the hood `mock_vast` injects a `Role::IO` backend via `io =>` — the same seam real
code uses.

## Tech and conventions

- **Moo** + **namespace::clean**; roles via `Moo::Role`. Conventions: skill `getty-perl-moo`.
- **JSON::MaybeXS**, **LWP::UserAgent** (default IO), **Log::Any** for logging, **URI**.
- **Dist::Zilla** with `[@Author::GETTY]`; POD is inline `=attr`/`=method`, deps live
  in `cpanfile`, one `package`/`$VERSION` per file. Details: skill
  `getty-perl-release-author-getty`.
