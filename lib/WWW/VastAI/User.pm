package WWW::VastAI::User;

use Moo;
extends 'WWW::VastAI::Object';

sub email   { shift->data->{email} }
sub balance { shift->data->{balance} }
sub ssh_key { shift->data->{ssh_key} }
sub sid     { shift->data->{sid} }

1;
