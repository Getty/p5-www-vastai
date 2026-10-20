package WWW::VastAI::LWPIO;
our $VERSION = '0.002';
# ABSTRACT: Default LWP::UserAgent-backed IO backend for WWW::VastAI

use Moo;
use HTTP::Request;
use LWP::UserAgent;
use WWW::VastAI::HTTPResponse;

with 'WWW::VastAI::Role::IO';

has user_agent => (
    is      => 'lazy',
    builder => sub {
        LWP::UserAgent->new(
            agent   => 'WWW-VastAI',
            timeout => 30,
        );
    },
);

sub call {
    my ($self, $req) = @_;

    my $http = HTTP::Request->new($req->method => $req->url);
    for my $name (keys %{ $req->headers }) {
        $http->header($name => $req->headers->{$name});
    }
    $http->content($req->content) if $req->has_content;

    my $response = $self->user_agent->request($http);

    # LWP answers a transport failure itself: it never reaches the server and
    # marks its own answer with "Client-Warning: Internal response".
    my $is_network = ( $response->header('Client-Warning') || '' ) =~ /^Internal response/i ? 1 : 0;

    return WWW::VastAI::HTTPResponse->new(
        status     => $response->code,
        # bytes, not characters: the caller decodes the JSON itself
        content    => $response->decoded_content( charset => 'none' ),
        is_network => $is_network,
    );
}

1;

=head1 DESCRIPTION

L<WWW::VastAI::LWPIO> is the default synchronous transport backend for
L<WWW::VastAI>. It adapts internal L<WWW::VastAI::HTTPRequest> objects to
L<HTTP::Request> and wraps L<LWP::UserAgent> responses as
L<WWW::VastAI::HTTPResponse>.

=head1 METHODS

=head2 user_agent

Returns the underlying L<LWP::UserAgent> instance used for requests.

=head2 call

    my $response = $io->call($request);

Executes a L<WWW::VastAI::HTTPRequest> and returns a
L<WWW::VastAI::HTTPResponse>. The body is handed over as bytes and a
transport failure is flagged with C<is_network>.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::Role::IO>, L<LWP::UserAgent>

=cut
