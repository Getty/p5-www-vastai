package WWW::VastAI::HTTPResponse;

# ABSTRACT: Internal HTTP response value object for pluggable IO backends

use Moo;

has status  => ( is => 'ro', required => 1 );
has content => ( is => 'ro', default  => sub { '' } );

1;

=head1 DESCRIPTION

L<WWW::VastAI::HTTPResponse> is the transport-neutral response object returned
by implementations of L<WWW::VastAI::Role::IO>.

=head1 METHODS

=head2 status

Returns the numeric HTTP status code.

=head2 content

Returns the decoded response body content.

=head1 SEE ALSO

L<WWW::VastAI::Role::IO>, L<WWW::VastAI::HTTPRequest>, L<WWW::VastAI::LWPIO>

=cut
