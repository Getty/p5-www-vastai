package WWW::VastAI::APIKey;

# ABSTRACT: API key wrapper for Vast.ai account credentials

use Moo;
extends 'WWW::VastAI::Object';

sub key         { shift->data->{key} }
sub rights      { shift->data->{rights} }
sub permissions { shift->data->{permissions} }

sub delete {
    my ($self) = @_;
    return $self->_client->api_keys->delete($self->id);
}

1;

=head1 DESCRIPTION

L<WWW::VastAI::APIKey> wraps an API key record returned by
L<WWW::VastAI::API::APIKeys>.

=head1 METHODS

=head2 key

Returns the API key token string.

=head2 rights

Returns the legacy rights value when the API includes it.

=head2 permissions

Returns the permission list from the API payload.

=head2 delete

Deletes the API key and returns the raw API response.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::API::APIKeys>

=cut
