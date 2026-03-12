package WWW::VastAI::HTTPRequest;
our $VERSION = '0.002';
# ABSTRACT: Internal HTTP request value object for pluggable IO backends

use Moo;

has method  => ( is => 'ro', required => 1 );
has url     => ( is => 'ro', required => 1 );
has headers => ( is => 'ro', default  => sub { {} } );
has content => ( is => 'ro' );

sub has_content { defined shift->content }

1;

=head1 DESCRIPTION

L<WWW::VastAI::HTTPRequest> is the transport-neutral request object passed to
implementations of L<WWW::VastAI::Role::IO>.

=head1 METHODS

=head2 method

Returns the HTTP method verb for the request.

=head2 url

Returns the absolute request URL.

=head2 headers

Returns the header hashref that will be sent to the backend.

=head2 content

Returns the raw request body, if any.

=head2 has_content

    if ($request->has_content) { ... }

Returns true when the request includes a content body.

=head1 SEE ALSO

L<WWW::VastAI::Role::IO>, L<WWW::VastAI::HTTPResponse>, L<WWW::VastAI::LWPIO>

=cut
