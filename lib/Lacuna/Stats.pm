package Lacuna::Stats;

=head1 LEGAL

=cut

use Moose;
use Modern::Perl;
extends ('Lacuna::WSWrapper');

use Data::Dumper;

has 'total_empires' => (
    is        => 'rw',
    isa       => 'Int',
);

has 'EMPIRE' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'empire_size_rank'
);

has 'UNIVERSITY' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'university_level_rank'
);

has 'OFFENSE' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'offense_success_rate_rank'
);

has 'DEFENSE' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'defense_success_rate_rank'
);

has 'DIRTIEST' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'dirtiest_rank'
);

sub BUILD {
    my $self    = shift;
    $self->url("/stats");
}

#--------------------------------------------------------------------
#                   Public Methods
#--------------------------------------------------------------------

#-----------------------------------------------
=head2 get_total_empires()

Gets the total number of empires in the expanse.

=cut

sub get_total_empires {
    my $self       = shift;
    unless ($self->total_empires) {
        $self->get_empire_stats;
    }
    return $self->total_empires;
}

#-----------------------------------------------
=head2 get_empire_stats( [ page ] )

Quick method to get empire_size_rank stats for the server

=head3 page

Optional page number to get stats for.  If no page number is passed in
the first page of stats will be returned.

=cut

sub get_empire_stats {
    my $self       = shift;
    my $session    = $self->session;
    my $page       = shift || 1;

    my $result     = $self->empire_rank([
        $session->session_id,
        $self->EMPIRE,
        $page
    ]);

    $self->total_empires($result->{total_empires});

    return $result->{empires};
}

#--------------------------------------------------------------------
#                   Private Methods
#--------------------------------------------------------------------


__PACKAGE__->meta->make_immutable;



=head1 NAME

Package Lacuna::Stats

=head1 DESCRIPTION

Returns stats for Lacuna

=head1 SYNOPSIS

use Lacuna::Stats;

=head1 METHODS

These methods are available from this class:

=cut


1;

#vim:ft=perl
