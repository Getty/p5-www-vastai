package WWW::VastAI::Volume;
our $VERSION = '0.002';
# ABSTRACT: Volume wrapper for Vast.ai storage resources

use Moo;
extends 'WWW::VastAI::Object';

sub status      { shift->data->{status} }
sub machine_id  { shift->data->{machine_id} }
sub public_ipaddr { shift->data->{public_ipaddr} }

sub delete {
    my ($self) = @_;
    return $self->_client->volumes->delete($self->id);
}

1;

=head1 DESCRIPTION

L<WWW::VastAI::Volume> represents a storage volume returned by
L<WWW::VastAI::API::Volumes>.

=head1 METHODS

=head2 status

Returns the current volume status.

=head2 machine_id

Returns the associated machine ID when present.

=head2 public_ipaddr

Returns the public IP address reported for the volume.

=head2 delete

    $volume->delete;

Deletes the volume through the parent client and returns the raw API response.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::API::Volumes>

=cut
