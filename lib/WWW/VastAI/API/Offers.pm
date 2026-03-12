package WWW::VastAI::API::Offers;

# ABSTRACT: Marketplace offer search for Vast.ai

use Moo;
use WWW::VastAI::Offer;
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::VastAI::Offer->new(
        client => $self->client,
        data   => $data,
    );
}

sub search {
    my ($self, %filters) = @_;

    my $result = $self->client->request_op('searchOffers', body => \%filters);
    my $offers = ref $result eq 'HASH' ? ($result->{offers} || $result->{results} || []) : ($result || []);
    return [ map { $self->_wrap($_) } @{$offers} ];
}

1;

=head1 SYNOPSIS

    my $offers = $vast->offers->search(
        limit    => 10,
        verified => { eq => \1 },
        rentable => { eq => \1 },
        rented   => { eq => \0 },
    );

=head1 DESCRIPTION

Provides access to the Vast.ai offer search endpoint. Search results are
returned as L<WWW::VastAI::Offer> objects.

=head1 METHODS

=head2 search

    my $offers = $vast->offers->search(%filters);

Runs a marketplace search with the given filter body and returns an arrayref of
L<WWW::VastAI::Offer> objects.

=cut
