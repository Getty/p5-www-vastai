package WWW::VastAI::API::Invoices;

# ABSTRACT: Invoice listing for Vast.ai v1 billing endpoints

use Moo;
use WWW::VastAI::Invoice;
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub list {
    my ($self, %query) = @_;
    my $result = $self->client->request_op('listInvoices', query => \%query);
    my $invoices = ref $result eq 'HASH' ? ($result->{invoices} || $result->{results} || []) : ($result || []);
    return [
        map {
            WWW::VastAI::Invoice->new(
                client => $self->client,
                data   => $_,
            )
        } @{$invoices}
    ];
}

1;

=head1 DESCRIPTION

Lists billing invoices from the Vast.ai C</api/v1> endpoints and returns
L<WWW::VastAI::Invoice> objects.

=head1 METHODS

=head2 list

    my $invoices = $vast->invoices->list(limit => 10);

Lists invoice records.

=cut
