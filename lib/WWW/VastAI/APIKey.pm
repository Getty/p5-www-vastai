package WWW::VastAI::APIKey;

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
