package WWW::VastAI::User;
our $VERSION = '0.002';
# ABSTRACT: Current-user payload wrapper for Vast.ai accounts

use Moo;
extends 'WWW::VastAI::Object';

sub email   { shift->data->{email} }
sub balance { shift->data->{balance} }
sub ssh_key { shift->data->{ssh_key} }
sub sid     { shift->data->{sid} }

1;

=head1 DESCRIPTION

L<WWW::VastAI::User> wraps the current-user profile returned by
L<WWW::VastAI::API::User>.

=head1 METHODS

=head2 email

Returns the account email address.

=head2 balance

Returns the current account balance.

=head2 ssh_key

Returns the primary SSH key string when present.

=head2 sid

Returns the Vast.ai user SID.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::API::User>

=cut
