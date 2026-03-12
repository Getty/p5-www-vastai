package WWW::VastAI::SSHKey;

# ABSTRACT: Account SSH key wrapper with update and delete helpers

use Moo;
extends 'WWW::VastAI::Object';

sub key {
    my ($self) = @_;
    return $self->data->{key} // $self->data->{public_key};
}
sub created_at { shift->data->{created_at} }

sub update {
    my ($self, $ssh_key) = @_;
    return $self->_replace_data($self->_client->ssh_keys->update($self->id, $ssh_key)->raw);
}

sub delete {
    my ($self) = @_;
    return $self->_client->ssh_keys->delete($self->id);
}

1;

=head1 DESCRIPTION

L<WWW::VastAI::SSHKey> represents an SSH key managed by
L<WWW::VastAI::API::SSHKeys>.

=head1 METHODS

=head2 key

    my $public_key = $ssh_key->key;

Returns the public key text, normalizing either C<key> or C<public_key> from
the API payload.

=head2 created_at

Returns the payload creation timestamp when available.

=head2 update

    $ssh_key->update($new_public_key);

Updates the SSH key and refreshes the local payload.

=head2 delete

Deletes the SSH key and returns the raw API response.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::API::SSHKeys>

=cut
