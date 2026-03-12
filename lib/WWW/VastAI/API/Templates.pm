package WWW::VastAI::API::Templates;

# ABSTRACT: Template listing and management for Vast.ai

use Moo;
use Carp qw(croak);
use WWW::VastAI::Template;
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::VastAI::Template->new(
        client => $self->client,
        data   => $data,
    );
}

sub list {
    my ($self, %query) = @_;
    my $result = $self->client->request_op('searchTemplates', query => \%query);
    my $templates = ref $result eq 'HASH' ? ($result->{templates} || $result->{results} || []) : ($result || []);
    return [ map { $self->_wrap($_) } @{$templates} ];
}

sub create {
    my ($self, %params) = @_;
    croak "name required"  unless $params{name};
    croak "image required" unless $params{image};

    my $result = $self->client->request_op('createTemplate', body => \%params);
    my $template = ref $result eq 'HASH' ? ($result->{template} || $result) : $result;
    return $self->_wrap($template);
}

sub update {
    my ($self, $hash_id, %params) = @_;
    croak "hash_id required" unless $hash_id;
    $params{hash_id} = $hash_id;

    my $result = $self->client->request_op('updateTemplate', body => \%params);
    my $template = ref $result eq 'HASH' ? ($result->{template} || $result) : $result;
    return $self->_wrap($template);
}

sub delete {
    my ($self, $id) = @_;
    croak "template id required" unless defined $id;
    return $self->client->request_op('deleteTemplate', body => { id => $id });
}

1;

=head1 DESCRIPTION

Wraps the Vast.ai template APIs and returns L<WWW::VastAI::Template> objects.

=head1 METHODS

=head2 list

    my $templates = $vast->templates->list(%query);

Lists templates. Structured filter arguments are JSON-encoded into the query
string by the shared HTTP layer.

=head2 create

=head2 update

=head2 delete

Create, update, or delete template definitions.

=cut
