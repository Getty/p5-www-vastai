package WWW::VastAI::Template;

use Moo;
extends 'WWW::VastAI::Object';

sub name    { shift->data->{name} }
sub hash_id { shift->data->{hash_id} }
sub image   { shift->data->{image} }

sub update {
    my ($self, %params) = @_;
    return $self->_replace_data($self->_client->templates->update($self->hash_id, %params)->raw);
}

sub delete {
    my ($self) = @_;
    return $self->_client->templates->delete($self->id);
}

1;
