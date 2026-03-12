package WWW::VastAI::Instance;

use Moo;
extends 'WWW::VastAI::Object';

sub label         { shift->data->{label} }
sub actual_status { shift->data->{actual_status} }
sub intended_status { shift->data->{intended_status} }
sub ssh_host      { shift->data->{ssh_host} }
sub ssh_port      { shift->data->{ssh_port} }
sub public_ipaddr { shift->data->{public_ipaddr} }
sub gpu_name      { shift->data->{gpu_name} }
sub num_gpus      { shift->data->{num_gpus} }

sub is_running { (shift->actual_status || '') eq 'running' }
sub is_stopped { (shift->actual_status || '') eq 'stopped' }

sub refresh {
    my ($self) = @_;
    return $self->_replace_data($self->_client->instances->get($self->id)->raw);
}

sub update {
    my ($self, %params) = @_;
    return $self->_replace_data($self->_client->instances->update($self->id, %params)->raw);
}

sub start {
    my ($self) = @_;
    $self->_client->instances->start($self->id);
    return $self;
}

sub stop {
    my ($self) = @_;
    $self->_client->instances->stop($self->id);
    return $self;
}

sub set_label {
    my ($self, $label) = @_;
    $self->_client->instances->label($self->id, $label);
    $self->data->{label} = $label;
    return $self;
}

sub logs {
    my ($self, %params) = @_;
    return $self->_client->instances->logs($self->id, %params);
}

sub ssh_keys {
    my ($self) = @_;
    return $self->_client->instances->ssh_keys($self->id);
}

sub attach_ssh_key {
    my ($self, $ssh_key) = @_;
    return $self->_client->instances->attach_ssh_key($self->id, $ssh_key);
}

sub detach_ssh_key {
    my ($self, $ssh_key_id) = @_;
    return $self->_client->instances->detach_ssh_key($self->id, $ssh_key_id);
}

sub delete {
    my ($self) = @_;
    return $self->_client->instances->delete($self->id);
}

1;
