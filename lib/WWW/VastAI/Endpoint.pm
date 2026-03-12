package WWW::VastAI::Endpoint;

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
