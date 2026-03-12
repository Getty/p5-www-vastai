package WWW::VastAI::Workergroup;
our $VERSION = '0.002';
# ABSTRACT: Serverless workergroup wrapper with management helpers

use Moo;
extends 'WWW::VastAI::Object';

sub endpoint_name { shift->data->{endpoint_name} }
sub endpoint_id   { shift->data->{endpoint_id} }
sub template_hash { shift->data->{template_hash} }
sub api_key       { shift->data->{api_key} }

sub workers {
    my ($self) = @_;
    return $self->_client->workergroups->workers($self->id);
}

sub logs {
    my ($self, %params) = @_;
    return $self->_client->workergroups->logs($self->id, %params);
}

sub update {
    my ($self, %params) = @_;
    return $self->_replace_data($self->_client->workergroups->update($self->id, %params)->raw);
}

sub delete {
    my ($self) = @_;
    return $self->_client->workergroups->delete($self->id);
}

1;

=head1 DESCRIPTION

L<WWW::VastAI::Workergroup> wraps a serverless workergroup managed through
L<WWW::VastAI::API::Workergroups>.

=head1 METHODS

=head2 endpoint_name

Returns the endpoint name this workergroup belongs to.

=head2 endpoint_id

Returns the endpoint identifier when present.

=head2 template_hash

Returns the template hash used by the workergroup.

=head2 api_key

Returns the API key associated with the workergroup when present.

=head2 workers

Returns worker information for the workergroup.

=head2 logs

Returns workergroup logs.

=head2 update

    $group->update(%params);

Updates the workergroup and refreshes the local payload.

=head2 delete

Deletes the workergroup and returns the raw API response.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::API::Workergroups>, L<WWW::VastAI::Endpoint>

=cut
