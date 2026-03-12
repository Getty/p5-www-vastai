package WWW::VastAI::Invoice;

# ABSTRACT: Billing invoice wrapper for Vast.ai account history

use Moo;
extends 'WWW::VastAI::Object';

sub type        { shift->data->{type} }
sub source      { shift->data->{source} }
sub description { shift->data->{description} }
sub amount      { shift->data->{amount} }

1;

=head1 DESCRIPTION

L<WWW::VastAI::Invoice> wraps a single invoice or billing line item returned by
L<WWW::VastAI::API::Invoices>.

=head1 METHODS

=head2 type

Returns the invoice entry type.

=head2 source

Returns the billing source or category.

=head2 description

Returns the human-readable line-item description.

=head2 amount

Returns the billed amount as provided by the API.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::API::Invoices>

=cut
