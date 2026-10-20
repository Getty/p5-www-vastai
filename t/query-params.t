#!/usr/bin/env perl

use strict;
use warnings;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use Test::More;
use URI;
use WWW::VastAI;
use WWW::VastAI::HTTPResponse;

my $LIB_DIR = File::Spec->rel2abs( File::Spec->catdir( $FindBin::Bin, File::Spec->updir, 'lib' ) );

# Stand-in for URI::QueryParam as it looked before the query methods were
# merged into URI itself: the module provides URI::query_param.
my $SHIM = <<'SHIM';
package URI::QueryParam;
use strict;
use warnings;
use URI::Escape ();

package URI;

sub query_param {
    my ($self, $key, $value) = @_;

    my @out;
    my $seen = 0;
    for my $pair ( grep { length } split /&/, ( defined $self->query ? $self->query : '' ) ) {
        my ($k) = split /=/, $pair, 2;
        if ( $k eq $key ) {
            next if $seen++;
            push @out, URI::Escape::uri_escape($key) . '=' . URI::Escape::uri_escape($value);
            next;
        }
        push @out, $pair;
    }
    push @out, URI::Escape::uri_escape($key) . '=' . URI::Escape::uri_escape($value) unless $seen;

    $self->query( join '&', @out );
    return $value;
}

package URI::QueryParam;

1;
SHIM

# Runs against a URI that does not ship query_param itself, so the method is
# only reachable when Role::HTTP loads URI::QueryParam.
my $CHILD = <<'CHILD';
use strict;
use warnings;
use URI;

my $uri = URI->new('https://console.vast.ai/api/v0/template/');
delete $URI::_query::{'query_param'} if defined &URI::_query::query_param;

require WWW::VastAI::Role::HTTP;

$uri->query_param( name => 'hello world' );
print $uri->as_string, "\n";
CHILD

{
    package Test::WWW::VastAI::CaptureIO;

    use Moo;
    use WWW::VastAI::HTTPResponse;

    with 'WWW::VastAI::Role::IO';

    has captured_url => ( is => 'rw' );

    sub call {
        my ($self, $req) = @_;
        $self->captured_url( $req->url );
        return WWW::VastAI::HTTPResponse->new(
            status  => 200,
            content => '{"ok":true}',
        );
    }
}

subtest 'GET params are encoded into the request URL query string' => sub {
    my $io   = Test::WWW::VastAI::CaptureIO->new;
    my $vast = WWW::VastAI->new( api_key => 'vast-test-key', io => $io );

    $vast->request_op(
        'searchTemplates',
        query => {
            name           => 'hello world',
            select_filters => { use_ssh => \1 },
        },
    );

    my $url = $io->captured_url;
    ok( defined $url, 'IO backend captured a request URL' );
    like(
        $url,
        qr{^\Qhttps://console.vast.ai/api/v0/template/\E\?},
        'query string appended after the GET path',
    );

    my $parsed = URI->new($url);
    is( $parsed->query_param('name'), 'hello world', 'plain string param round-trips' );
    is(
        $parsed->query_param('select_filters'),
        '{"use_ssh":true}',
        'ref param is JSON-encoded into the query',
    );
};

subtest 'query_param does not rely on a transitive URI::QueryParam load' => sub {
    my $dir      = tempdir( CLEANUP => 1 );
    my $shim_dir = File::Spec->catdir( $dir, 'shim' );
    my $script   = File::Spec->catfile( $dir, 'child.pl' );
    my $log_file = File::Spec->catfile( $dir, 'child.log' );

    make_path( File::Spec->catdir( $shim_dir, 'URI' ) );
    _write_file( File::Spec->catfile( $shim_dir, 'URI', 'QueryParam.pm' ), $SHIM );
    _write_file( $script, $CHILD );

    my $cmd = join ' ', map { "'$_'" } ( $^X, "-I$shim_dir", "-I$LIB_DIR", $script );
    my $rc  = system("$cmd > '$log_file' 2>&1");
    my $log = _read_file($log_file);

    is( $rc, 0, 'Role::HTTP provides query_param on its own' )
        or diag("child output:\n$log");
    like( $log, qr{\?name=hello(?:%20|\+)world}, 'query string built by the child' );
};

sub _write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $content;
    close $fh or die "cannot close $path: $!";
    return;
}

sub _read_file {
    my ($path) = @_;
    open my $fh, '<', $path or return '';
    local $/;
    my $content = <$fh>;
    close $fh;
    return defined $content ? $content : '';
}

done_testing;
