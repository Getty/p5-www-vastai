#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use WWW::VastAI::HTTPRequest;
use WWW::VastAI::HTTPResponse;
use WWW::VastAI::LWPIO;

{
    package Test::WWW::VastAI::FakeUA;

    sub new { bless {}, shift }

    sub request {
        my ($self, $request) = @_;
        $self->{request} = $request;
        $self->{response} = bless {
            code    => 201,
            content => '{"ok":true}',
            headers => {},
        }, 'Test::WWW::VastAI::FakeHTTPResponse';
        return $self->{response};
    }

    sub request_seen { shift->{request} }
    sub response_seen { shift->{response} }
}

{
    package Test::WWW::VastAI::FakeHTTPResponse;

    sub code { shift->{code} }

    sub header {
        my ($self, $name) = @_;
        return $self->{headers} ? $self->{headers}{ lc $name } : undef;
    }

    sub decoded_content {
        my ($self, %args) = @_;
        $self->{decoded_content_args} = {%args};
        return $self->{content};
    }

    sub decoded_content_args { shift->{decoded_content_args} }
}

subtest 'request and response wrappers expose payload state' => sub {
    my $request = WWW::VastAI::HTTPRequest->new(
        method  => 'POST',
        url     => 'https://example.invalid/instances',
        headers => {
            Authorization => 'Bearer token',
            'Content-Type' => 'application/json',
        },
        content => '{"name":"demo"}',
    );

    is($request->method, 'POST', 'request method');
    is($request->url, 'https://example.invalid/instances', 'request url');
    is($request->headers->{Authorization}, 'Bearer token', 'request header');
    ok($request->has_content, 'request reports content');

    my $empty = WWW::VastAI::HTTPRequest->new(
        method => 'GET',
        url    => 'https://example.invalid/instances',
    );
    ok(!$empty->has_content, 'empty request has no content');

    my $response = WWW::VastAI::HTTPResponse->new(
        status  => 202,
        content => '{"accepted":true}',
    );

    is($response->status, 202, 'response status');
    is($response->content, '{"accepted":true}', 'response content');
};

subtest 'lwpio converts internal request objects to lwp requests' => sub {
    my $ua = Test::WWW::VastAI::FakeUA->new;
    my $io = WWW::VastAI::LWPIO->new(user_agent => $ua);

    my $response = $io->call(
        WWW::VastAI::HTTPRequest->new(
            method  => 'POST',
            url     => 'https://example.invalid/instances',
            headers => {
                Authorization => 'Bearer token',
                'Content-Type' => 'application/json',
            },
            content => '{"name":"demo"}',
        )
    );

    isa_ok($response, 'WWW::VastAI::HTTPResponse');
    is($response->status, 201, 'lwpio forwards response status');
    is($response->content, '{"ok":true}', 'lwpio forwards decoded content');
    is($response->is_network, 0, 'an answer from the server is no network error');
    is_deeply(
        $ua->response_seen->decoded_content_args,
        { charset => 'none' },
        'lwpio takes the body as bytes'
    );

    my $sent = $ua->request_seen;
    isa_ok($sent, 'HTTP::Request');
    is($sent->method, 'POST', 'lwp request method');
    is($sent->uri->as_string, 'https://example.invalid/instances', 'lwp request uri');
    is($sent->header('Authorization'), 'Bearer token', 'lwp request header');
    is($sent->content, '{"name":"demo"}', 'lwp request content');
};

done_testing;
