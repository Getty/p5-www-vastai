package WWW::VastAI::HTTPResponse;
our $VERSION = '0.002';
# ABSTRACT: Internal HTTP response value object for pluggable IO backends

use Moo;

has status  => ( is => 'ro', required => 1 );
has content => ( is => 'ro', default  => sub { '' } );
has is_network => ( is => 'ro', default => sub { 0 } );

1;

=head1 DESCRIPTION

L<WWW::VastAI::HTTPResponse> is the transport-neutral response object returned
by implementations of L<WWW::VastAI::Role::IO>.

=head1 METHODS

=head2 status

Returns the numeric HTTP status code.

=head2 content

Returns the response body as received, as bytes. The bytes are decoded by the
caller, so a JSON body keeps its encoding.

=head2 is_network

Returns true when the backend got no answer from the server at all (DNS,
connect, TLS, timeout) and synthesized the response itself. False for every
answer that came from the server.

=head1 SEE ALSO

L<WWW::VastAI::Role::IO>, L<WWW::VastAI::HTTPRequest>, L<WWW::VastAI::LWPIO>

=cut
