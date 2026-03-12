package WWW::VastAI::API::Workergroups;
our $VERSION = '0.002';
# ABSTRACT: Workergroup management for Vast.ai serverless

use Moo;
use Carp qw(croak);
use WWW::VastAI::Workergroup;
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::VastAI::Workergroup->new(
        client => $self->client,
        data   => $data,
    );
}

sub list {
    my ($self) = @_;
    my $result = $self->client->request_op('listWorkergroups');
    my $groups = ref $result eq 'HASH' ? ($result->{workergroups} || $result->{results} || []) : ($result || []);
    return [ map { $self->_wrap($_) } @{$groups} ];
}

sub create {
    my ($self, %params) = @_;
    croak "template_hash required" unless $params{template_hash};
    croak "endpoint_name required" unless $params{endpoint_name};

    my $result = $self->client->request_op('createWorkergroup', body => \%params);
    my $group = ref $result eq 'HASH' ? ($result->{workergroup} || $result) : $result;
    return $self->_wrap($group);
}

sub update {
    my ($self, $id, %params) = @_;
    croak "workergroup id required" unless defined $id;

    my $result = $self->client->request_op(
        'updateWorkergroup',
        path => { id => $id },
        body => \%params,
    );

    my $group = ref $result eq 'HASH' ? ($result->{workergroup} || $result) : $result;
    return $self->_wrap($group);
}

sub delete {
    my ($self, $id) = @_;
    croak "workergroup id required" unless defined $id;
    return $self->client->request_op('deleteWorkergroup', path => { id => $id });
}

sub logs {
    my ($self, $id, %params) = @_;
    croak "workergroup id required" unless defined $id;
    my %body = ( workergroup_id => $id, %params );
    return $self->client->request_op('getWorkergroupLogs', body => \%body);
}

sub workers {
    my ($self, $id) = @_;
    croak "workergroup id required" unless defined $id;
    return $self->client->request_op('getWorkergroupWorkers', body => { workergroup_id => $id });
}

1;

=head1 DESCRIPTION

Wraps the Vast.ai workergroup APIs and the associated run-service calls for
worker and log inspection.

=head1 METHODS

=head2 list

Returns an arrayref of L<WWW::VastAI::Workergroup> objects.

=head2 create

Creates a workergroup and returns it as a L<WWW::VastAI::Workergroup> object.

=head2 update

Updates the workergroup identified by C<$id>.

=head2 delete

Deletes the workergroup identified by C<$id>.

=head2 workers

Returns worker information for a workergroup.

=head2 logs

Returns workergroup logs.

=cut
