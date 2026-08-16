package WWW::VastAI;

# ABSTRACT: Perl client for the Vast.ai REST APIs

use Moo;
use WWW::VastAI::API::APIKeys;
use WWW::VastAI::API::Endpoints;
use WWW::VastAI::API::EnvVars;
use WWW::VastAI::API::Instances;
use WWW::VastAI::API::Invoices;
use WWW::VastAI::API::Offers;
use WWW::VastAI::API::SSHKeys;
use WWW::VastAI::API::Templates;
use WWW::VastAI::API::User;
use WWW::VastAI::API::Volumes;
use WWW::VastAI::API::Workergroups;
use namespace::clean;

our $VERSION = '0.002';

has api_key => (
    is      => 'ro',
    default => sub { $ENV{VAST_API_KEY} },
);

has console_url => (
    is      => 'ro',
    default => sub { 'https://console.vast.ai' },
);

has base_url => (
    is      => 'lazy',
    builder => sub { shift->console_url . '/api/v0' },
);

has base_url_v1 => (
    is      => 'lazy',
    builder => sub { shift->console_url . '/api/v1' },
);

has run_url => (
    is      => 'ro',
    default => sub { 'https://run.vast.ai' },
);

with 'WWW::VastAI::Role::HTTP', 'WWW::VastAI::Role::OperationMap';

has offers => (
    is      => 'lazy',
    builder => sub { WWW::VastAI::API::Offers->new(client => shift) },
);

has instances => (
    is      => 'lazy',
    builder => sub { WWW::VastAI::API::Instances->new(client => shift) },
);

has templates => (
    is      => 'lazy',
    builder => sub { WWW::VastAI::API::Templates->new(client => shift) },
);

has volumes => (
    is      => 'lazy',
    builder => sub { WWW::VastAI::API::Volumes->new(client => shift) },
);

has ssh_keys => (
    is      => 'lazy',
    builder => sub { WWW::VastAI::API::SSHKeys->new(client => shift) },
);

has api_keys => (
    is      => 'lazy',
    builder => sub { WWW::VastAI::API::APIKeys->new(client => shift) },
);

has user => (
    is      => 'lazy',
    builder => sub { WWW::VastAI::API::User->new(client => shift) },
);

has env_vars => (
    is      => 'lazy',
    builder => sub { WWW::VastAI::API::EnvVars->new(client => shift) },
);

has invoices => (
    is      => 'lazy',
    builder => sub { WWW::VastAI::API::Invoices->new(client => shift) },
);

has endpoints => (
    is      => 'lazy',
    builder => sub { WWW::VastAI::API::Endpoints->new(client => shift) },
);

has workergroups => (
    is      => 'lazy',
    builder => sub { WWW::VastAI::API::Workergroups->new(client => shift) },
);

1;

=head1 SYNOPSIS

    use WWW::VastAI;

    my $vast = WWW::VastAI->new(
        api_key => $ENV{VAST_API_KEY},
    );

    # Search marketplace offers and rent an instance
    my $offers = $vast->offers->search(
        limit    => 5,
        verified => { eq => \1 },
        rentable => { eq => \1 },
        rented   => { eq => \0 },
        gpu_name => { in => ['RTX_4090', 'RTX_5090'] },
    );

    my $instance = $offers->[0]->create_instance(
        image   => 'vastai/base-image:@vastai-automatic-tag',
        disk    => 32,
        runtype => 'ssh',
    );

    $instance->bid_price(0.42);
    $instance->execute('nvidia-smi');
    $instance->stop;
    $instance->delete;

    # Account management
    my $user = $vast->user->current;
    my $subs = $vast->user->subaccounts;

    # Templates, volumes, serverless
    my $templates = $vast->templates->list;
    my $volumes   = $vast->volumes->list;
    my $endpoints = $vast->endpoints->list;

=head1 DESCRIPTION

WWW::VastAI provides a Perl client for the Vast.ai REST APIs. It covers:

=over 4

=item * marketplace offer search

=item * instance lifecycle, bid/prepay/recycle helpers, and instance
SSH/log/command helpers

=item * templates

=item * volumes

=item * SSH keys, API keys, user profile, subaccounts, cloud integrations,
IP history, credit transfer, and env vars

=item * invoices (v1)

=item * serverless endpoints, route requests, workergroups, logs and workers

=back

The request routing is driven by a central operation map
(L<WWW::VastAI::Role::OperationMap>), following the same idea as
OpenAPI-backed clients while keeping the distribution lightweight. The
HTTP transport is pluggable through L<WWW::VastAI::Role::IO>.

=attr api_key

Vast.ai API key for authentication. Defaults to C<$ENV{VAST_API_KEY}>.

=attr console_url

Base URL for the Vast.ai console. Defaults to C<https://console.vast.ai>.

=attr run_url

Base URL for the Vast.ai serverless run service. Defaults to
C<https://run.vast.ai>.

=attr io

Pluggable IO backend. Defaults to L<WWW::VastAI::LWPIO>.

=attr offers

Lazy accessor returning a L<WWW::VastAI::API::Offers> controller.

=attr instances

Lazy accessor returning a L<WWW::VastAI::API::Instances> controller.

=attr templates

Lazy accessor returning a L<WWW::VastAI::API::Templates> controller.

=attr volumes

Lazy accessor returning a L<WWW::VastAI::API::Volumes> controller.

=attr ssh_keys

Lazy accessor returning a L<WWW::VastAI::API::SSHKeys> controller.

=attr api_keys

Lazy accessor returning a L<WWW::VastAI::API::APIKeys> controller.

=attr user

Lazy accessor returning a L<WWW::VastAI::API::User> controller.

=attr env_vars

Lazy accessor returning a L<WWW::VastAI::API::EnvVars> controller.

=attr invoices

Lazy accessor returning a L<WWW::VastAI::API::Invoices> controller.

=attr endpoints

Lazy accessor returning a L<WWW::VastAI::API::Endpoints> controller.

=attr workergroups

Lazy accessor returning a L<WWW::VastAI::API::Workergroups> controller.

=head1 LIVE TESTING

The distribution ships with three optional live tests:

=over 4

=item * C<t/90-live-vastai.t> - read-only, no-cost API coverage

=item * C<t/91-live-vastai-cost.t> - cost-incurring instance lifecycle test

=item * C<t/92-live-vastai-volume.t> - cost-incurring volume lifecycle test

=back

These tests are skipped unless the corresponding environment variables are set.
Use C<VAST_LIVE_TEST=1> for read-only live coverage and add
C<VAST_LIVE_ALLOW_COST=1> to enable the instance and volume lifecycle tests.

=head1 SEE ALSO

L<WWW::VastAI::API::Offers>, L<WWW::VastAI::API::Instances>,
L<WWW::VastAI::API::Templates>, L<WWW::VastAI::API::Volumes>,
L<WWW::VastAI::API::SSHKeys>, L<WWW::VastAI::API::APIKeys>,
L<WWW::VastAI::API::User>, L<WWW::VastAI::API::EnvVars>,
L<WWW::VastAI::API::Invoices>,
L<WWW::VastAI::API::Endpoints>, L<WWW::VastAI::API::Workergroups>,
L<WWW::VastAI::Role::OperationMap>, L<WWW::VastAI::Role::HTTP>

=cut
