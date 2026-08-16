# WWW-VastAI

Perl client for the Vast.ai REST APIs.

## Installation

```bash
cpanm WWW::VastAI
```

## Coverage

- marketplace offers
- instances and lifecycle actions (start, stop, bid, prepay, reboot, recycle,
  execute commands, logs, per-instance SSH keys)
- templates
- volumes
- SSH keys and API keys
- current user, profile updates, subaccounts, cloud integrations, IP history,
  credit transfer, and env vars
- invoices (v1 billing)
- serverless endpoints, synchronous route calls, workergroups, logs and workers

## Basic usage

```perl
use WWW::VastAI;

my $vast = WWW::VastAI->new(
    api_key => $ENV{VAST_API_KEY},
);

# Search marketplace offers
my $offers = $vast->offers->search(
    limit    => 5,
    verified => { eq => \1 },
    rentable => { eq => \1 },
    rented   => { eq => \0 },
    gpu_name => { in => ['RTX_4090', 'RTX_5090'] },
);

# Rent an instance from the cheapest offer
my $instance = $offers->[0]->create_instance(
    image   => 'vastai/base-image:@vastai-automatic-tag',
    disk    => 32,
    runtype => 'ssh',
);

# Instance lifecycle helpers
$instance->bid_price(0.42);
$instance->execute('nvidia-smi');
$instance->reboot;
$instance->stop;
$instance->delete;
```

## Account management

```perl
# Current user profile
my $user = $vast->user->current;
say $user->email, ' balance: ', $user->balance;

# Update profile
$vast->user->update(full_name => 'Ops Bot');

# Subaccounts
my $sub = $vast->user->create_subaccount(email => 'bot@example.invalid');
my $subs = $vast->user->subaccounts;

# Cloud integrations and IP history
my $integrations = $vast->user->connections;
my $ips = $vast->user->ipaddrs;

# Credit transfer
$vast->user->transfer_credit(recipient => $sub->id, amount => 5.00);

# SSH keys
my $keys = $vast->ssh_keys->list;
my $key  = $vast->ssh_keys->create('ssh-ed25519 AAAA...');

# API keys
my $api_keys = $vast->api_keys->list;
my $new_key  = $vast->api_keys->create(name => 'ci-bot');

# Environment variables / secrets
my $secrets = $vast->env_vars->list;
$vast->env_vars->create(name => 'HF_TOKEN', value => '...');
```

## Templates and volumes

```perl
# Templates
my $templates = $vast->templates->list(
    select_filters => { use_ssh => { eq => \1 } },
);

my $tmpl = $vast->templates->create(
    name  => 'my-worker',
    image => 'pytorch/pytorch:latest',
);
$tmpl->update(name => 'my-worker-v2');
$tmpl->delete;

# Volumes
my $volumes = $vast->volumes->list;
my $vol = $vast->volumes->create(size => 10, label => 'training-cache');
$vol->delete;
```

## Serverless endpoints

```perl
# Create an endpoint
my $endpoint = $vast->endpoints->create(
    endpoint_name => 'llama-dev',
    min_load      => 0,
    target_util   => 0.7,
);

# Route a synchronous request
my $result = $endpoint->route(input => 'ping');

# Inspect workers and logs
my $workers = $endpoint->workers;
my $logs    = $endpoint->logs;

# Update and delete
$endpoint->update(min_load => 1);
$endpoint->delete;

# Workergroups
my $groups = $vast->workergroups->list;
my $group  = $vast->workergroups->create(
    endpoint_name => 'llama-dev',
    template_hash => 'abc123',
);
my $wlogs = $group->logs;
$group->delete;
```

## Invoices

```perl
my $invoices = $vast->invoices->list(limit => 20);
for my $inv (@$invoices) {
    say join "\t", $inv->type, $inv->amount, $inv->description;
}
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

VAST_LIVE_TEST=1 VAST_LIVE_ALLOW_COST=1 VAST_API_KEY=... \
  prove -lv t/92-live-vastai-volume.t
```

## Architecture

The client is built in layers:

- **WWW::VastAI** - main entry point with lazy resource accessors
- **WWW::VastAI::API::\*** - resource controllers wrapping named API operations
- **WWW::VastAI::\*** - entity objects with convenience methods
- **WWW::VastAI::Role::OperationMap** - central route table (56 operations)
- **WWW::VastAI::Role::HTTP** - request building, auth, JSON, error handling
- **WWW::VastAI::Role::IO** / **WWW::VastAI::LWPIO** - pluggable transport

## Documentation

The main module POD covers the client entry point and all attributes.
Resource-specific details live in the API and entity classes:

- [WWW::VastAI::API::Offers](lib/WWW/VastAI/API/Offers.pm),
  [WWW::VastAI::Offer](lib/WWW/VastAI/Offer.pm)
- [WWW::VastAI::API::Instances](lib/WWW/VastAI/API/Instances.pm),
  [WWW::VastAI::Instance](lib/WWW/VastAI/Instance.pm)
- [WWW::VastAI::API::Templates](lib/WWW/VastAI/API/Templates.pm),
  [WWW::VastAI::Template](lib/WWW/VastAI/Template.pm)
- [WWW::VastAI::API::Volumes](lib/WWW/VastAI/API/Volumes.pm),
  [WWW::VastAI::Volume](lib/WWW/VastAI/Volume.pm)
- [WWW::VastAI::API::SSHKeys](lib/WWW/VastAI/API/SSHKeys.pm),
  [WWW::VastAI::API::APIKeys](lib/WWW/VastAI/API/APIKeys.pm)
- [WWW::VastAI::API::User](lib/WWW/VastAI/API/User.pm),
  [WWW::VastAI::API::EnvVars](lib/WWW/VastAI/API/EnvVars.pm)
- [WWW::VastAI::API::Invoices](lib/WWW/VastAI/API/Invoices.pm)
- [WWW::VastAI::API::Endpoints](lib/WWW/VastAI/API/Endpoints.pm),
  [WWW::VastAI::API::Workergroups](lib/WWW/VastAI/API/Workergroups.pm)
