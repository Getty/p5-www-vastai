package WWW::VastAI::API::User;
our $VERSION = '0.002';
# ABSTRACT: Current-user access for Vast.ai

use Moo;
use Carp qw(croak);
use WWW::VastAI::User;
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub current {
    my ($self) = @_;
    my $result = $self->client->request_op('getCurrentUser');
    my $user = ref $result eq 'HASH' ? ($result->{user} || $result) : $result;
    return WWW::VastAI::User->new(
        client => $self->client,
        data   => $user,
    );
}

sub update {
    my ($self, %params) = @_;
    my $result = $self->client->request_op('updateCurrentUser', body => \%params);
    my $user = ref $result eq 'HASH' ? ($result->{user} || $result) : $result;
    return WWW::VastAI::User->new(
        client => $self->client,
        data   => $user,
    );
}

sub create_subaccount {
    my ($self, %params) = @_;
    croak "email required" unless $params{email};

    my $result = $self->client->request_op('createSubaccount', body => \%params);
    my $user = ref $result eq 'HASH' ? ($result->{user} || $result) : $result;
    return WWW::VastAI::User->new(
        client => $self->client,
        data   => $user,
    );
}

sub connections {
    my ($self) = @_;
    my $result = $self->client->request_op('listCloudIntegrations');
    return ref $result eq 'HASH' ? ($result->{cloud_integrations} || $result->{results} || []) : ($result || []);
}

sub ipaddrs {
    my ($self, $user_id) = @_;
    $user_id = 'me' unless defined $user_id;
    my $result = $self->client->request_op('listUserIPAddrs', path => { user_id => $user_id });
    return ref $result eq 'HASH' ? ($result->{ipaddrs} || $result->{results} || []) : ($result || []);
}

sub subaccounts {
    my ($self) = @_;
    my $result = $self->client->request_op('listSubaccounts');
    my $users = ref $result eq 'HASH' ? ($result->{users} || $result->{subaccounts} || $result->{results} || []) : ($result || []);
    return [
        map {
            WWW::VastAI::User->new(
                client => $self->client,
                data   => $_,
            )
        } @{$users}
    ];
}

sub transfer_credit {
    my ($self, %params) = @_;
    croak "recipient required" unless defined $params{recipient};
    croak "amount required" unless defined $params{amount};
    return $self->client->request_op('transferCredit', body => \%params);
}

1;

=head1 DESCRIPTION

Fetches the current authenticated Vast.ai user as a L<WWW::VastAI::User>
object.

=head1 METHODS

=head2 current

Returns the currently authenticated user profile.

=head2 update

    my $user = $vast->user->update(full_name => 'Ops Bot');

Updates the current account and returns a refreshed
L<WWW::VastAI::User> object.

=head2 create_subaccount

    my $user = $vast->user->create_subaccount(email => 'bot@example.invalid');

Creates a subaccount and returns it as a L<WWW::VastAI::User> object.

=head2 connections

Returns configured cloud integrations for the authenticated account.

=head2 ipaddrs

    my $ips = $vast->user->ipaddrs;

Returns IP address history for the current user. Pass a specific user ID to
query a different account when the API allows it.

=head2 subaccounts

Returns subaccounts as L<WWW::VastAI::User> objects.

=head2 transfer_credit

Transfers account credit and returns the raw API response.

=cut
