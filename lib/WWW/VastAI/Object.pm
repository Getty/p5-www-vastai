package WWW::VastAI::Object;

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
