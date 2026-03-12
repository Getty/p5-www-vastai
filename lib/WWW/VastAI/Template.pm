package WWW::VastAI::Template;
our $VERSION = '0.002';
# ABSTRACT: Template wrapper with update and delete helpers

use Moo;
extends 'WWW::VastAI::Object';

sub name    { shift->data->{name} }
sub hash_id { shift->data->{hash_id} }
sub image   { shift->data->{image} }

sub update {
    my ($self, %params) = @_;
    return $self->_replace_data($self->_client->templates->update($self->hash_id, %params)->raw);
}

sub delete {
    my ($self) = @_;
    return $self->_client->templates->delete($self->id);
}

1;

=head1 DESCRIPTION

L<WWW::VastAI::Template> wraps a Vast.ai template payload and delegates updates
and deletion to L<WWW::VastAI::API::Templates>.

=head1 METHODS

=head2 name

Returns the template name.

=head2 hash_id

Returns the template hash identifier.

=head2 image

Returns the template image reference.

=head2 update

    $template->update(%params);

Updates the template using its C<hash_id> and refreshes the local payload.

=head2 delete

Deletes the template and returns the raw API response.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::API::Templates>

=cut
