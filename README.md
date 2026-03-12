# WWW-VastAI

Perl client for the Vast.ai REST APIs.

## Coverage

- marketplace offers
- instances and lifecycle actions
- templates
- volumes
- SSH keys and API keys
- current user and env vars
- invoices
- serverless endpoints and workergroups

## Basic usage

```perl
use WWW::VastAI;

my $vast = WWW::VastAI->new(
    api_key => $ENV{VAST_API_KEY},
);

my $offers = $vast->offers->search(
    limit    => 5,
    verified => { eq => \1 },
    rentable => { eq => \1 },
    rented   => { eq => \0 },
);

my $instance = $vast->instances->create(
    $offers->[0]->ask_contract_id,
    image   => 'nginx:alpine',
    disk    => 16,
    runtype => 'args',
    label   => 'demo-instance',
);
```

## Tests

Normal test suite:

```bash
prove -lr t
```

No-cost live test:

```bash
VAST_LIVE_TEST=1 VAST_API_KEY=... prove -lv t/90-live-vastai.t
```

Cost-incurring live tests:

```bash
VAST_LIVE_TEST=1 VAST_LIVE_ALLOW_COST=1 VAST_API_KEY=... \
  prove -lv t/91-live-vastai-cost.t
```

Volume lifecycle test under the same cost gate:

```bash
VAST_LIVE_TEST=1 VAST_LIVE_ALLOW_COST=1 VAST_API_KEY=... \
  prove -lv t/92-live-vastai-volume.t
```
