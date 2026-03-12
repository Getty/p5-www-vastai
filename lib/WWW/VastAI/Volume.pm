package WWW::VastAI::Volume;

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
