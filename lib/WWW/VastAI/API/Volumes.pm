package WWW::VastAI::API::Volumes;
our $VERSION = '0.002';
# ABSTRACT: Volume creation and deletion for Vast.ai

use Moo;
use Carp qw(croak);
use WWW::VastAI::Volume;
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::VastAI::Volume->new(
        client => $self->client,
        data   => $data,
    );
}

sub list {
    my ($self) = @_;
    my $result = $self->client->request_op('listVolumes');
    my $volumes = ref $result eq 'HASH' ? ($result->{volumes} || $result->{results} || []) : ($result || []);
    return [ map { $self->_wrap($_) } @{$volumes} ];
}

sub create {
    my ($self, %params) = @_;
    croak "size required" unless defined $params{size};
    croak "label required" unless defined $params{label};

    my $result = $self->client->request_op('createVolume', body => \%params);
    my $volume = ref $result eq 'HASH' ? ($result->{volume} || $result) : { id => $result };
    return $self->_wrap($volume);
}

sub delete {
    my ($self, $id) = @_;
    croak "volume id required" unless defined $id;
    return $self->client->request_op('deleteVolume', body => { id => $id });
}

1;

=head1 DESCRIPTION

Provides access to the Vast.ai volume endpoints and returns
L<WWW::VastAI::Volume> objects.

=head1 METHODS

=head2 list

Returns an arrayref of volume objects.

=head2 create

    my $volume = $vast->volumes->create(
        size  => 10,
        label => 'training-cache',
    );

Creates a volume and returns a wrapped object. If the API only returns a scalar
ID, the returned object contains that ID.

=head2 delete

Deletes a volume by ID.

=cut
