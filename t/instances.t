#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::VastAI::Mock;

subtest 'instance lifecycle and helpers' => sub {
    my $instance_101 = {
        id            => 101,
        label         => 'worker-a',
        actual_status => 'running',
        ssh_host      => '203.0.113.11',
        ssh_port      => 30222,
    };

    my $vast = mock_vast(
        'GET /instances/' => {
            instances => [
                { %{$instance_101} },
            ],
        },
        'GET /instances/101/' => sub {
            return { instances => { %{$instance_101} } };
        },
        'PUT /asks/501/' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{image}, 'vastai/base', 'image forwarded');
            is($opts{body}{disk}, 32, 'disk forwarded');
            return { new_contract => 202 };
        },
        'GET /instances/202/' => {
            instances => {
                id            => 202,
                label         => 'fresh-box',
                actual_status => 'running',
                ssh_host      => '203.0.113.99',
                ssh_port      => 40222,
            },
        },
        'PUT /instances/101/' => sub {
            my ($method, $path, %opts) = @_;
            $instance_101->{label} = $opts{body}{label} if exists $opts{body}{label};
            $instance_101->{actual_status} = $opts{body}{state} if exists $opts{body}{state};
            return { success => 1 };
        },
        'PUT /instances/bid_price/101/' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{price}, 0.42, 'bid price forwarded');
            return { success => 1 };
        },
        'GET /instances/balance/101/' => {
            balance => '9.50',
        },
        'PUT /instances/prepay/101/' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{amount}, 12.5, 'prepay amount forwarded');
            return { success => 1 };
        },
        'PUT /instances/reboot/101/' => { success => 1 },
        'PUT /instances/recycle/101/' => { success => 1 },
        'PUT /instances/command/101/' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{command}, 'nvidia-smi', 'command forwarded');
            return { success => 1, result_url => 'https://results.example.invalid/101' };
        },
        'PUT /instances/request_logs/101' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{tail}, 5, 'tail forwarded');
            return { logs => "line-a\nline-b\n" };
        },
        'GET /instances/101/ssh/' => {
            ssh_keys => [
                { id => 88, public_key => 'ssh-ed25519 AAAA test@unit' },
            ],
        },
        'POST /instances/101/ssh/' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{ssh_key}, 'ssh-ed25519 BBBB other@test', 'ssh key forwarded');
            return { success => 1 };
        },
        'DELETE /instances/101/ssh/88/' => { success => 1 },
        'DELETE /instances/101/' => { success => 1 },
    );

    my $instances = $vast->instances->list;
    is(scalar @{$instances}, 1, 'one instance');
    isa_ok($instances->[0], 'WWW::VastAI::Instance');
    ok($instances->[0]->is_running, 'instance status helper');

    my $instance = $vast->instances->get(101);
    is($instance->ssh_port, 30222, 'get returns instance');

    my $created = $vast->instances->create(
        501,
        image   => 'vastai/base',
        disk    => 32,
        runtype => 'ssh',
    );
    is($created->id, 202, 'create wraps new instance');

    my $renamed = $vast->instances->label(101, 'renamed-node');
    is($renamed->label, 'renamed-node', 'label update');

    my $stopped = $vast->instances->stop(101);
    is($stopped->actual_status, 'stopped', 'stop maps to state update');
    ok($instance->bid_price(0.42)->{success}, 'bid price update');
    is($instance->deposit->{balance}, '9.50', 'deposit lookup');
    ok($instance->prepay(amount => 12.5)->{success}, 'prepay');
    ok($instance->reboot->{success}, 'reboot');
    ok($instance->recycle->{success}, 'recycle');
    like($instance->execute('nvidia-smi')->{result_url}, qr/results\.example/, 'execute returns result url');

    my $logs = $vast->instances->logs(101, tail => 5);
    like($logs, qr/line-a/, 'logs returned');

    my $keys = $vast->instances->ssh_keys(101);
    is(scalar @{$keys}, 1, 'one attached ssh key');

    ok($vast->instances->attach_ssh_key(101, 'ssh-ed25519 BBBB other@test')->{success}, 'attach ssh key');
    ok($vast->instances->detach_ssh_key(101, 88)->{success}, 'detach ssh key');
    ok($instance->delete->{success}, 'delete via object');
};

subtest 'instance creation validates required inputs' => sub {
    my $vast = mock_vast();

    eval { $vast->instances->create() };
    like($@, qr/offer_id required/, 'offer required');

    eval { $vast->instances->create(123) };
    like($@, qr/image or template_hash_id required/, 'image or template required');
};

done_testing;
