package WWW::VastAI::Role::HTTP;
our $VERSION = '0.002';
# ABSTRACT: Shared synchronous HTTP client role for Vast.ai API consumers

use Moo::Role;
use Carp qw(croak);
use JSON::MaybeXS qw(decode_json encode_json);
use Log::Any qw($log);
use URI;
use URI::QueryParam;
use WWW::VastAI::Error;
use WWW::VastAI::HTTPRequest;
use WWW::VastAI::LWPIO;

requires 'api_key';
requires 'base_url';

# how much of a response body ends up in an error message
my $ERROR_BODY_LIMIT = 200;

has io => (
    is      => 'lazy',
    builder => sub { WWW::VastAI::LWPIO->new },
);

sub get {
    my ($self, $path, %opts) = @_;
    return $self->_request('GET', $path, %opts);
}

sub post {
    my ($self, $path, $body, %opts) = @_;
    return $self->_request('POST', $path, %opts, body => $body);
}

sub put {
    my ($self, $path, $body, %opts) = @_;
    return $self->_request('PUT', $path, %opts, body => $body);
}

sub delete {
    my ($self, $path, $body, %opts) = @_;
    return $self->_request('DELETE', $path, %opts, (defined $body ? (body => $body) : ()));
}

sub _set_auth {
    my ($self, $headers) = @_;
    $headers->{Authorization} = 'Bearer ' . $self->api_key;
}

sub _build_query_uri {
    my ($self, $url, $params) = @_;

    my $uri = URI->new($url);
    for my $name (sort keys %{$params || {}}) {
        my $value = $params->{$name};
        next unless defined $value;
        $value = encode_json($value) if ref $value;
        $uri->query_param($name => $value);
    }

    return $uri->as_string;
}

sub _build_request {
    my ($self, $method, $path, %opts) = @_;

    my $base_url = $opts{base_url} || $self->base_url;
    my $url = $base_url . $path;
    $url = $self->_build_query_uri($url, $opts{params}) if $opts{params};

    my %headers = (
        'Content-Type' => 'application/json',
    );
    $self->_set_auth(\%headers);

    my %args = (
        method  => $method,
        url     => $url,
        headers => \%headers,
    );

    if (exists $opts{body}) {
        $args{content} = encode_json($opts{body});
        $log->debugf('%s %s body=%s', $method, $url, $args{content});
    }
    else {
        $log->debugf('%s %s', $method, $url);
    }

    return WWW::VastAI::HTTPRequest->new(%args);
}

sub _parse_response {
    my ($self, $response, $method, $path) = @_;

    my $content = $response->content;
    $content = '' unless defined $content;

    my $data;
    my $broken = 0;
    if ( length $content && $content =~ /\A\s*[\{\[]/ ) {
        $data = eval { decode_json($content) };
        if ($@) {
            $broken = 1;
            undef $data;
        }
    }
    elsif ( length $content ) {
        $data = $content;
    }

    my $status     = $response->status;
    my $is_network = $response->is_network ? 1 : 0;

    if ( $is_network || $broken || $status < 200 || $status >= 300 ) {
        WWW::VastAI::Error->throw(
            message    => $self->_error_message( $data, $content, $status, $broken, $is_network ),
            method     => $method,
            path       => $path,
            status     => $status,
            is_network => $is_network,
            data       => $data,
            body       => $content,
        );
    }

    $log->infof('%s %s -> %s', $method, $path, $status);
    return $data;
}

sub _error_message {
    my ( $self, $data, $content, $status, $broken, $is_network ) = @_;

    if ($broken) {
        return 'unparseable response body: ' . $self->_truncate($content);
    }

    if ($is_network) {
        my $message = $self->_truncate($content);
        return length $message ? $message : $status;
    }

    if ( ref $data eq 'HASH' ) {
        my $message = $data->{msg} || $data->{message} || $data->{error};
        $message = undef if ref $message;
        return defined $message ? $message : $status;
    }

    return ( defined $data && length $data ) ? $self->_truncate($data) : $status;
}

sub _truncate {
    my ( $self, $text ) = @_;

    return '' unless defined $text;
    $text =~ s/\s+/ /g;
    $text =~ s/\A\s+//;
    $text =~ s/\s+\z//;
    return $text if length $text <= $ERROR_BODY_LIMIT;

    return substr( $text, 0, $ERROR_BODY_LIMIT ) . '...';
}

sub _request {
    my ($self, $method, $path, %opts) = @_;

    croak "No Vast.ai API key configured" unless $self->api_key;

    my $req = $self->_build_request($method, $path, %opts);
    my $response = $self->io->call($req);
    return $self->_parse_response($response, $method, $path);
}

1;

=head1 DESCRIPTION

This role provides the low-level HTTP functionality used by L<WWW::VastAI>.
It handles bearer authentication, JSON encoding/decoding, pluggable IO
backends, and uniform error handling.

=head1 REQUIRED ATTRIBUTES

=over 4

=item * C<api_key>

=item * C<base_url>

=back

=head1 METHODS

=head2 get

    my $data = $client->get('/instances/');

Performs a GET request.

=head2 post

    my $data = $client->post('/bundles/', \%body);

Performs a POST request with a JSON body.

=head2 put

    my $data = $client->put('/instances/123/', \%body);

Performs a PUT request with a JSON body.

=head2 delete

    my $data = $client->delete('/instances/123/');
    my $data = $client->delete('/template/', { id => 123 });

Performs a DELETE request. Vast.ai uses both path-only and JSON-body delete
styles, so an optional body is supported.

=head1 ERRORS

A failed call throws a L<WWW::VastAI::Error>. It carries the C<status>, the
C<method> and the C<path> of the failed request, the decoded C<data> and the
raw C<body>. C<is_network> is true when no answer came from Vast.ai at all.

The exception stringifies to C<Vast.ai API error: message (status 404, GET
/instances/123/)>, so C<$@ =~ /Vast\.ai API error: .../> keeps matching. A
transport failure reads C<Vast.ai connection error: ...> and a body that is no
valid JSON is reported as C<unparseable response body: ...> instead of dying
with a JSON parser message.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::Error>, L<WWW::VastAI::Role::IO>,
L<WWW::VastAI::LWPIO>

=cut
