package WWW::VastAI::API::User;

# ABSTRACT: Current-user access for Vast.ai

use Moo;
use WWW::VastAI::User;
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub current {
    my ($self) = @_;
    my $result = $self->client->request_op('getCurrentUser');
    my $user = ref $result eq 'HASH' ? ($result->{user} || $result) : $result;
    return WWW::VastAI::User->new(
        client => $self->client,
        data   => $user,
    );
}

1;

=head1 DESCRIPTION

Fetches the current authenticated Vast.ai user as a L<WWW::VastAI::User>
object.

=head1 METHODS

=head2 current

Returns the currently authenticated user profile.

=cut
