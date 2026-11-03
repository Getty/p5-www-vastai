requires 'HTTP::Request';
requires 'JSON::MaybeXS';
requires 'Log::Any';
requires 'LWP::Protocol::https';
requires 'LWP::UserAgent';
requires 'Moo';
requires 'namespace::clean';
requires 'URI';

on test => sub {
    requires 'Test::More';
};
