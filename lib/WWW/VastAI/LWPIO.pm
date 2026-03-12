package WWW::VastAI::LWPIO;

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

    return WWW::VastAI::HTTPResponse->new(
        status  => $response->code,
        content => $response->decoded_content,
    );
}

1;
