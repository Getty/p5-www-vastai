package WWW::VastAI::Endpoint;

# ABSTRACT: Serverless endpoint wrapper with worker and log helpers

use Moo;
extends 'WWW::VastAI::Object';

sub endpoint_name  { shift->data->{endpoint_name} }
sub endpoint_state { shift->data->{endpoint_state} }
sub api_key        { shift->data->{api_key} }

sub workers {
    my ($self) = @_;
    return $self->_client->endpoints->workers($self->id);
}

sub logs {
    my ($self, %params) = @_;
    return $self->_client->endpoints->logs($self->endpoint_name, %params);
}

sub delete {
    my ($self) = @_;
    return $self->_client->endpoints->delete($self->id);
}

1;

=head1 DESCRIPTION

L<WWW::VastAI::Endpoint> wraps a serverless endpoint returned by
L<WWW::VastAI::API::Endpoints>.

=head1 METHODS

=head2 endpoint_name

Returns the endpoint name used by the serverless API.

=head2 endpoint_state

Returns the current endpoint state string.

=head2 api_key

Returns the API key associated with the endpoint when present.

=head2 workers

    my $workers = $endpoint->workers;

Fetches worker information for the endpoint.

=head2 logs

    my $logs = $endpoint->logs(%params);

Fetches endpoint logs using the endpoint name.

=head2 delete

Deletes the endpoint and returns the raw API response.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::API::Endpoints>, L<WWW::VastAI::Workergroup>

=cut
