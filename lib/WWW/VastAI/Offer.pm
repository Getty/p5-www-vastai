package WWW::VastAI::Offer;

use Moo;
extends 'WWW::VastAI::Object';

sub ask_contract_id {
    my ($self) = @_;
    return $self->data->{ask_contract_id} // $self->data->{id};
}
sub gpu_name        { shift->data->{gpu_name} }
sub num_gpus        { shift->data->{num_gpus} }
sub dph_total       { shift->data->{dph_total} }
sub machine_id      { shift->data->{machine_id} }

sub create_instance {
    my ($self, %params) = @_;
    return $self->_client->instances->create($self->ask_contract_id, %params);
}

1;
