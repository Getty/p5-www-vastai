package WWW::VastAI::Object;
our $VERSION = '0.002';
# ABSTRACT: Base entity wrapper for Vast.ai API resources

use Moo;

has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has data => (
    is       => 'rw',
    required => 1,
);

sub id  { shift->data->{id} }
sub raw { shift->data }

sub _replace_data {
    my ($self, $data) = @_;
    $self->data($data);
    return $self;
}

1;

=head1 DESCRIPTION

L<WWW::VastAI::Object> stores the raw decoded API payload for a resource object
and keeps a weak reference back to the owning L<WWW::VastAI> client. Resource
classes such as L<WWW::VastAI::Offer> and L<WWW::VastAI::Instance> inherit from
this class.

=head1 METHODS

=head2 id

    my $id = $object->id;

Returns the resource identifier from the underlying payload.

=head2 raw

    my $payload = $object->raw;

Returns the raw decoded payload hashref for the resource.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::Offer>, L<WWW::VastAI::Instance>

=cut
