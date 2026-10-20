package WWW::VastAI::Error;
# ABSTRACT: Exception object thrown for failed Vast.ai API calls

use Moo;
use Carp qw(croak);
use namespace::clean;
# after namespace::clean on purpose: it would sweep the overload entries
use overload
    '""'     => sub { $_[0]->to_string },
    'bool'   => sub { 1 },
    fallback => 1;

our $VERSION = '0.002';

has message => ( is => 'ro', default => sub { 'unknown error' } );

=attr message

Human readable message: the C<msg>, C<message> or C<error> field of the API
answer, the (truncated) response body or the HTTP status code.

=cut

has method => ( is => 'ro' );

=attr method

HTTP method of the failed request, e.g. C<GET>.

=cut

has path => ( is => 'ro' );

=attr path

Request path of the failed call, e.g. C</instances/123/>.

=cut

has status => ( is => 'ro' );

=attr status

HTTP status code, e.g. C<404>. For a transport failure this is the status the
IO backend synthesized, e.g. C<500>.

=cut

has is_network => ( is => 'ro', default => sub { 0 } );

=attr is_network

True when no answer came from Vast.ai at all (DNS, connect, TLS, timeout), as
opposed to Vast.ai answering with an error status.

=cut

has data => ( is => 'ro' );

=attr data

The decoded response body, or undef when it was missing or not valid JSON.

=cut

has body => ( is => 'ro' );

=attr body

The raw response body as received.

=cut

sub throw {
    my ( $class, %args ) = @_;
    croak $class->new(%args);
}

=method throw

    WWW::VastAI::Error->throw( message => 'not found', status => 404 );

Constructs the object and throws it.

=cut

sub to_string {
    my ($self) = @_;

    my $prefix = $self->is_network ? 'Vast.ai connection error' : 'Vast.ai API error';

    my $context = '';
    $context = 'status ' . $self->status if defined $self->status;
    if ( defined $self->method && defined $self->path ) {
        $context .= ( length $context ? ', ' : '' ) . $self->method . ' ' . $self->path;
    }

    return $prefix . ': ' . $self->message
        . ( length $context ? ' (' . $context . ')' : '' );
}

=method to_string

The string form: C<Vast.ai API error: message (status 404, GET /instances/123/)>
for a failed API call, C<Vast.ai connection error: ...> when no answer came
from Vast.ai at all. The leading C<Vast.ai API error: message> stays the way
it was, so C<$@ =~ /Vast\.ai API error: .../> keeps matching.

=cut

1;
