package Lacuna::Building;

=head1 LEGAL

=cut

use Moose;
use Modern::Perl;
extends ('Lacuna::WSWrapper');

use Data::Dumper;

has 'planet'     => (
    is        => 'ro',
    isa       => 'Lacuna::Planet',
    predicate => 'has_planet'
);

has 'building_data'    => (
    is        => 'ro',
    isa       => 'Any',
    predicate => 'has_building_data',
);

has 'building_id' => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_building_id',
);

has 'name' => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_name',
);

has 'level' => (
    is        => 'ro',
    isa       => 'Int',
    predicate => 'has_level',
);

has 'x' => (
    is        => 'ro',
    isa       => 'Int',
    predicate => 'has_x',
);

has 'y' => (
    is        => 'ro',
    isa       => 'Int',
    predicate => 'has_y',
);

has 'build_remaining' => (
    is        => 'ro',
    isa       => 'Int'
);

has 'work_remaining' => (
    is        => 'ro',
    isa       => 'Int'
);

has 'repair_costs' => (
    is        => 'ro',
    isa       => 'HashRef'
);

has 'view_data' => (
    is        => 'rw',
    isa       => 'HashRef',
);

around BUILDARGS => sub {
    my $orig           = shift;
    my $class          = shift;

    my $session        = shift;
    my $planet         = shift;
    my $building_id    = shift;
    my $building_data  = shift;

    my $pending_build  = $building_data->{pending_build} || {};
    my $work_remaining = $building_data->{work} || {};
    my $repair_costs   = $building_data->{repair_costs} || {};

    return $class->$orig(
        session          => $session,
        planet           => $planet,
        building_id      => $building_id,
        building_data    => $building_data,
        name             => $building_data->{name},
        level            => $building_data->{level},
        url              => $building_data->{url},
        x                => $building_data->{x},
        y                => $building_data->{y},
        build_remaining  => ($pending_build->{seconds_remaining} || 0),
        work_remaining   => ($work_remaining->{seconds_remaining} || 0),
        repair_costs     => $repair_costs,
    );
    
};


#--------------------------------------------------------------------
#                   Public Methods
#--------------------------------------------------------------------

#-----------------------------------------------
=head2 upgrade

Requests an upgrade for the building

=cut

sub upgrade {
    my $self      = shift;
    my $session   = $self->session;

    my $req_obj  = $session->callLacuna($self->url,"upgrade",[
        $session->session_id,
        $self->building_id
    ]);

    if($req_obj->error) {
        print "Could not upgrade building ".$self->name.": ".$req_obj->error->message." (".$req_obj->error->code.")\n";
        return undef;
    }

    return $req_obj->result;
}

#-----------------------------------------------
=head2 view

Returns the view for the building.

=cut

sub view {
    my $self      = shift;

    my $session   = $self->session;

    unless ($self->view_data) {
        my $req_obj  = $session->callLacuna($self->url,"view",[
            $session->session_id,
            $self->building_id
        ]);

        if($req_obj->error) {
            print "Could not retreive building ".$self->name.": ".$req_obj->error->message." (".$req_obj->error->code.")\n";
            return undef;
        }

        $self->view_data($req_obj->result);
    }
    

    return $self->view_data;
}

#-----------------------------------------------
=head2 repair

Repairs a building

=cut

sub repair {
    my $self      = shift;
    my $session   = $self->session;
    
    my $req_obj  = $session->callLacuna($self->url,"repair",[
        $session->session_id,
        $self->building_id
    ]);

    if($req_obj->error) {
        print "Could not repair building ".$self->name.": ".$req_obj->error->message." (".$req_obj->error->code.")\n";
        return undef;
    }

    return $req_obj->result;
}


#--------------------------------------------------------------------
#                   Private Methods
#--------------------------------------------------------------------


__PACKAGE__->meta->make_immutable;



=head1 NAME

Package Lacuna::Session

=head1 DESCRIPTION

A Lacuna Session based on successful login

=head1 SYNOPSIS

use Lacuna::Session;

=head1 METHODS

These methods are available from this class:

=cut


1;

#vim:ft=perl
