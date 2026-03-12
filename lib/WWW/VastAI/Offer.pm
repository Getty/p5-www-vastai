package WWW::VastAI::Offer;

# ABSTRACT: Marketplace offer wrapper returned by Vast.ai searches

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

=head1 DESCRIPTION

L<WWW::VastAI::Offer> wraps a single marketplace offer returned by
L<WWW::VastAI::API::Offers>. It provides small convenience accessors for common
offer fields and a helper to create an instance from the selected offer.

=head1 METHODS

=head2 ask_contract_id

    my $offer_id = $offer->ask_contract_id;

Returns the ask contract identifier used for instance creation. If the payload
does not provide a dedicated C<ask_contract_id>, the regular resource C<id> is
used as a fallback.

=head2 gpu_name

Returns the GPU model for the offer.

=head2 num_gpus

Returns the number of GPUs in the offer.

=head2 dph_total

Returns the hourly price field from the offer payload.

=head2 machine_id

Returns the provider machine identifier.

=head2 create_instance

    my $instance = $offer->create_instance(%params);

Creates a new L<WWW::VastAI::Instance> via the parent client using this offer's
contract ID.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::API::Offers>, L<WWW::VastAI::Instance>

=cut
