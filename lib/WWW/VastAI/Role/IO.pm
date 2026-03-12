package WWW::VastAI::Role::IO;
our $VERSION = '0.002';
# ABSTRACT: Role for pluggable HTTP backends used by WWW::VastAI

use Moo::Role;

requires 'call';

1;

=head1 DESCRIPTION

L<WWW::VastAI::Role::IO> defines the minimal interface required by
L<WWW::VastAI> transport backends. A backend receives a
L<WWW::VastAI::HTTPRequest> and must return a L<WWW::VastAI::HTTPResponse>.

=head1 REQUIRED METHODS

=head2 call

    my $response = $io->call($request);

Executes the given L<WWW::VastAI::HTTPRequest> and returns a
L<WWW::VastAI::HTTPResponse>.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::HTTPRequest>, L<WWW::VastAI::HTTPResponse>,
L<WWW::VastAI::LWPIO>

=cut
