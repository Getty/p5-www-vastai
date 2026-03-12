package WWW::VastAI::SSHKey;

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
