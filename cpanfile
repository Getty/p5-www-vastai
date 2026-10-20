requires 'HTTP::Request';
requires 'JSON::MaybeXS';
requires 'LWP::UserAgent';
requires 'LWP::Protocol::https';
requires 'Log::Any';
requires 'Moo';
requires 'namespace::clean';
requires 'URI';

on test => sub {
    requires 'Test::More';
};
