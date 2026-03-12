package WWW::VastAI::API::APIKeys;

# ABSTRACT: API key management for Vast.ai

use Moo;
use Carp qw(croak);
use WWW::VastAI::APIKey;
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::VastAI::APIKey->new(
        client => $self->client,
        data   => $data,
    );
}

sub list {
    my ($self) = @_;
    my $result = $self->client->request_op('listAPIKeys');
    my $keys = ref $result eq 'HASH' ? ($result->{api_keys} || $result->{results} || []) : ($result || []);
    return [ map { $self->_wrap($_) } @{$keys} ];
}

sub create {
    my ($self, %params) = @_;
    croak "name required" unless $params{name};

    my $result = $self->client->request_op('createAPIKey', body => \%params);
    my $key = ref $result eq 'HASH' ? ($result->{api_key} || $result) : $result;
    return $self->_wrap($key);
}

sub delete {
    my ($self, $id) = @_;
    croak "api key id required" unless defined $id;
    return $self->client->request_op('deleteAPIKey', path => { id => $id });
}

1;

=head1 DESCRIPTION

Lists, creates, and deletes Vast.ai API keys. Results are wrapped as
L<WWW::VastAI::APIKey> objects.

=head1 METHODS

=head2 list

=head2 create

=head2 delete

=cut
