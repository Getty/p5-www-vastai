package WWW::VastAI::Invoice;

use Moo;
extends 'WWW::VastAI::Object';

sub type        { shift->data->{type} }
sub source      { shift->data->{source} }
sub description { shift->data->{description} }
sub amount      { shift->data->{amount} }

1;
