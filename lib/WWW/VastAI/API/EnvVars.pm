package WWW::VastAI::API::EnvVars;

# ABSTRACT: Environment variable and secret management for Vast.ai

use Moo;
use Carp qw(croak);
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub list {
    my ($self) = @_;
    my $result = $self->client->request_op('listEnvVars');
    return ref $result eq 'HASH' ? ($result->{secrets} || $result->{results} || $result) : $result;
}

sub create {
    my ($self, %params) = @_;
    croak "name required"  unless $params{name};
    croak "value required" unless exists $params{value};
    return $self->client->request_op('createEnvVar', body => \%params);
}

sub update {
    my ($self, %params) = @_;
    croak "name required"  unless $params{name};
    croak "value required" unless exists $params{value};
    return $self->client->request_op('updateEnvVar', body => \%params);
}

sub delete {
    my ($self, $name) = @_;
    croak "name required" unless defined $name;
    return $self->client->request_op('deleteEnvVar', body => { name => $name });
}

1;

=head1 DESCRIPTION

Wraps the Vast.ai secrets/environment-variable endpoints.

=head1 METHODS

=head2 list

Returns the current env-var/secrets structure from the API.

=head2 create

Creates a new environment variable or secret.

=head2 update

Updates an existing environment variable or secret.

=head2 delete

Deletes the named environment variable or secret.

=cut
