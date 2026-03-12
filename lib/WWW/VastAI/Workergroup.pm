package WWW::VastAI::Workergroup;

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
