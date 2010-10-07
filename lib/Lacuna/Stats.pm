package Lacuna::Stats;

=head1 LEGAL

=cut

use Moose;
use Modern::Perl;

use Data::Dumper;

has 'session'    => (
    is        => 'ro',
    isa       => 'Lacuna::Session',
    predicate => 'has_session'
);

has 'url'     => (
    is        => 'ro',
    isa       => 'Str',
    default   => '/stats'
);

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

around BUILDARGS => sub {
    my $orig          = shift;
    my $class         = shift;

    my $session       = shift;

    return $class->$orig( session => $session );
    
};


#--------------------------------------------------------------------
#                   Public Methods
#--------------------------------------------------------------------

#-----------------------------------------------
=head2 get_empire_stats()

Send a message to the account passed in

=cut

sub get_total_empires {
    my $self       = shift;
    unless ($self->total_empires) {
        $self->get_empire_stats;
    }
    return $self->total_empires;
}

#-----------------------------------------------
=head2 get_empire_stats()

Send a message to the account passed in

=cut

sub get_empire_stats {
    my $self       = shift;
    my $session    = $self->session;
    my $page       = shift || 1;

    #( session_id, [ sort_by, page_number ] )

    my $req_obj  = $session->callLacuna($self->url,"empire_rank",[
        $session->session_id,
        $self->EMPIRE,
        $page
    ]);

    if($req_obj->error) {
        print "Could not get empire stats: ".$req_obj->error->message." (".$req_obj->error->code.")\n";
        return [];
    }

    $self->total_empires($req_obj->result->{total_empires});

    return $req_obj->result->{empires};
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
