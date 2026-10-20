#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Scalar::Util qw(blessed);

use WWW::VastAI;
use WWW::VastAI::HTTPRequest;
use WWW::VastAI::LWPIO;

{
    package Test::WWW::VastAI::FakeResponse;

    sub new { my ( $class, %args ) = @_; return bless {%args}, $class }
    sub status     { return $_[0]->{status} }
    sub content    { return $_[0]->{content} }
    sub is_network { return $_[0]->{is_network} ? 1 : 0 }
}

{
    package Test::WWW::VastAI::StaticIO;

    sub new { my ( $class, %args ) = @_; return bless {%args}, $class }
    sub call { return $_[0]->{response} }
}

{
    package Test::WWW::VastAI::FakeHTTPResponse;

    sub new { my ( $class, %args ) = @_; return bless {%args}, $class }

    sub code { return $_[0]->{code} }

    sub header {
        my ( $self, $name ) = @_;
        return $self->{headers} ? $self->{headers}{ lc $name } : undef;
    }

    # models HTTP::Message: without a charset the body comes back as
    # characters, with charset => 'none' as bytes
    sub decoded_content {
        my ( $self, %args ) = @_;
        $self->{decoded_content_args} = {%args};
        return $self->{bytes} if lc( $args{charset} || '' ) eq 'none';
        require Encode;
        return Encode::decode( 'UTF-8', $self->{bytes} );
    }

    sub decoded_content_args { return $_[0]->{decoded_content_args} }
}

{
    package Test::WWW::VastAI::FakeUA;

    sub new { my ( $class, %args ) = @_; return bless {%args}, $class }

    sub request {
        my ( $self, $req ) = @_;
        $self->{last_request} = $req;
        return $self->{response};
    }

    sub response     { return $_[0]->{response} }
    sub last_request { return $_[0]->{last_request} }
}

sub client_with {
    my (%args) = @_;
    return WWW::VastAI->new(
        api_key => 'vast-test-key',
        io      => Test::WWW::VastAI::StaticIO->new(
            response => Test::WWW::VastAI::FakeResponse->new(%args),
        ),
    );
}

sub catch_error {
    my ($code) = @_;
    eval { $code->(); 1 };
    return $@;
}

subtest 'a failed API call reports status, method and path' => sub {
    my $client = client_with(
        status  => 404,
        content => '{"msg":"instance not found"}',
    );

    my $err = catch_error( sub { $client->get('/instances/123/') } );

    isa_ok( $err, 'WWW::VastAI::Error', 'a failed call throws a WWW::VastAI::Error' );
    like( "$err", qr/^Vast\.ai API error: instance not found/, 'the error text reads as it did before' );
    like( "$err", qr/\(status 404, GET \/instances\/123\/\)/, 'the error text carries status, method and path' );

    SKIP: {
        skip 'no exception object', 5
            unless blessed $err && $err->isa('WWW::VastAI::Error');
        is( $err->status, 404, 'the error carries the status' );
        is( $err->method, 'GET', 'the error carries the method' );
        is( $err->path, '/instances/123/', 'the error carries the path' );
        ok( !$err->is_network, 'an API error is not a network error' );
        is_deeply( $err->data, { msg => 'instance not found' }, 'the decoded body is kept' );
    }
};

subtest 'a long error body is truncated in the message' => sub {
    my $body = '<!DOCTYPE html><html><head><title>502 Bad Gateway</title></head><body>'
        . ( 'x' x 3000 )
        . '</body></html>';
    my $client = client_with( status => 502, content => $body );

    my $err = catch_error( sub { $client->get('/instances/') } );

    like( "$err", qr/^Vast\.ai API error: <!DOCTYPE html>/, 'the message starts with the body' );
    unlike( "$err", qr/x{300}/, 'the whole error page is not dumped into the message' );
    cmp_ok( length "$err", '<', 400, 'the message stays short' );

    SKIP: {
        skip 'no exception object', 1
            unless blessed $err && $err->isa('WWW::VastAI::Error');
        is( length $err->body, length $body, 'the full body is still available' );
    }
};

subtest 'a transport failure is distinguishable from an API error' => sub {
    my $client = client_with(
        status     => 500,
        content    => "Can't connect to console.vast.ai:443 (Connection refused)",
        is_network => 1,
    );

    my $err = catch_error( sub { $client->get('/instances/') } );

    like( "$err", qr/^Vast\.ai connection error: Can't connect to console\.vast\.ai:443/,
        'the message names the transport failure' );
    unlike( "$err", qr/Vast\.ai API error/, 'a transport failure does not read as an API error' );

    SKIP: {
        skip 'no exception object', 1
            unless blessed $err && $err->isa('WWW::VastAI::Error');
        ok( $err->is_network, 'the error is flagged as a network error' );
    }
};

subtest 'a broken JSON body does not die with a JSON parser message' => sub {
    my $client = client_with( status => 200, content => '{"msg": "truncated' );

    my $err = catch_error( sub { $client->get('/instances/') } );

    isa_ok( $err, 'WWW::VastAI::Error', 'a broken body is reported as a Vast.ai error' );
    like( "$err", qr/unparseable response body/, 'the message names the problem' );
    like( "$err", qr/truncated/, 'the message shows the body' );
};

subtest 'the lwp backend hands the body over as bytes' => sub {
    my $ua = Test::WWW::VastAI::FakeUA->new(
        response => Test::WWW::VastAI::FakeHTTPResponse->new(
            code    => 200,
            bytes   => "{\"msg\":\"caf\xc3\xa9\"}",
            headers => { 'content-type' => 'application/json' },
        ),
    );
    my $io = WWW::VastAI::LWPIO->new( user_agent => $ua );

    my $response = $io->call(
        WWW::VastAI::HTTPRequest->new(
            method => 'GET',
            url    => 'https://console.vast.ai/api/v0/instances/',
        )
    );

    is_deeply(
        $ua->response->decoded_content_args,
        { charset => 'none' },
        'the body is taken as bytes and not as decoded characters'
    );
    is( $response->content, "{\"msg\":\"caf\xc3\xa9\"}", 'the body is handed over unchanged' );
};

subtest 'the lwp backend flags a transport failure' => sub {
    my $ua = Test::WWW::VastAI::FakeUA->new(
        response => Test::WWW::VastAI::FakeHTTPResponse->new(
            code    => 500,
            bytes   => "Can't connect to console.vast.ai:443 (Connection refused)\n",
            headers => { 'client-warning' => 'Internal response' },
        ),
    );
    my $client = WWW::VastAI->new(
        api_key => 'vast-test-key',
        io      => WWW::VastAI::LWPIO->new( user_agent => $ua ),
    );

    my $err = catch_error( sub { $client->get('/instances/') } );

    like( "$err", qr/^Vast\.ai connection error: Can't connect to console\.vast\.ai:443/,
        'the transport failure is not reported as an API error' );
};

subtest 'a non-ASCII answer is decoded from the bytes' => sub {
    my $ua = Test::WWW::VastAI::FakeUA->new(
        response => Test::WWW::VastAI::FakeHTTPResponse->new(
            code    => 200,
            bytes   => "{\"msg\":\"caf\xc3\xa9\"}",
            headers => { 'content-type' => 'application/json' },
        ),
    );
    my $client = WWW::VastAI->new(
        api_key => 'vast-test-key',
        io      => WWW::VastAI::LWPIO->new( user_agent => $ua ),
    );

    my $data = $client->get('/instances/');
    is( $data->{msg}, "caf\x{e9}", 'the answer is decoded to characters' );
};

done_testing;
