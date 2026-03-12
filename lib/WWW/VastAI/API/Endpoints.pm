package WWW::VastAI::API::Endpoints;
our $VERSION = '0.002';
# ABSTRACT: Serverless endpoint management for Vast.ai

use Moo;
use Carp qw(croak);
use WWW::VastAI::Endpoint;
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::VastAI::Endpoint->new(
        client => $self->client,
        data   => $data,
    );
}

sub list {
    my ($self) = @_;
    my $result = $self->client->request_op('listEndpoints');
    my $endpoints = ref $result eq 'HASH' ? ($result->{endpoints} || $result->{results} || []) : ($result || []);
    return [ map { $self->_wrap($_) } @{$endpoints} ];
}

sub create {
    my ($self, %params) = @_;
    croak "endpoint_name required" unless $params{endpoint_name};
    croak "min_load required"      unless exists $params{min_load};
    croak "target_util required"   unless exists $params{target_util};

    my $result = $self->client->request_op('createEndpoint', body => \%params);
    my $endpoint = ref $result eq 'HASH' ? ($result->{endpoint} || $result) : $result;
    $endpoint = {
        id => $result->{result},
        %params,
    } if ref $result eq 'HASH' && !$result->{endpoint} && defined $result->{result} && ref $result->{result} ne 'HASH';
    return $self->_wrap($endpoint);
}

sub update {
    my ($self, $id, %params) = @_;
    croak "endpoint id required" unless defined $id;

    my $result = $self->client->request_op(
        'updateEndpoint',
        path => { id => $id },
        body => \%params,
    );

    my $endpoint = ref $result eq 'HASH' ? ($result->{endpoint} || $result) : $result;
    $endpoint = {
        id => $id,
        %params,
    } if ref $result eq 'HASH' && !$result->{endpoint} && $result->{success};

    return $self->_wrap($endpoint);
}

sub delete {
    my ($self, $id) = @_;
    croak "endpoint id required" unless defined $id;
    return $self->client->request_op('deleteEndpoint', path => { id => $id });
}

sub route {
    my ($self, $endpoint_name, %params) = @_;
    croak "endpoint_name required" unless $endpoint_name;
    return $self->client->request_op(
        'routeEndpointRequest',
        body => {
            endpoint => $endpoint_name,
            %params,
        },
    );
}

sub logs {
    my ($self, $endpoint_name, %params) = @_;
    croak "endpoint_name required" unless $endpoint_name;
    my %body = ( endpoint => $endpoint_name, %params );
    return $self->client->request_op('getEndpointLogs', body => \%body);
}

sub workers {
    my ($self, $endpoint_id) = @_;
    croak "endpoint id required" unless defined $endpoint_id;
    return $self->client->request_op('getEndpointWorkers', body => { id => $endpoint_id });
}

1;

=head1 DESCRIPTION

Provides access to Vast.ai serverless endpoint management plus helper calls for
endpoint workers and logs.

=head1 METHODS

=head2 list

Returns an arrayref of L<WWW::VastAI::Endpoint> objects.

=head2 create

Creates a new endpoint and returns it as a L<WWW::VastAI::Endpoint> object.

=head2 delete

Deletes the endpoint identified by C<$id>.

=head2 update

    my $endpoint = $vast->endpoints->update($id, min_load => 1);

Updates the endpoint and returns a L<WWW::VastAI::Endpoint> object.

=head2 route

    my $result = $vast->endpoints->route('llama-prod', input => 'ping');

Sends a synchronous request through the Vast.ai C</route/> API.

=head2 workers

Fetches worker information for a serverless endpoint.

=head2 logs

Fetches logs for a serverless endpoint by endpoint name.

=cut
