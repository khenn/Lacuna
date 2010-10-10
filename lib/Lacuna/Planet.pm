package Lacuna::Planet;

=head1 LEGAL

=cut

use Moose;

use Lacuna::Building;
use Module::Find;
use Modern::Perl;
extends ('Lacuna::WSWrapper');

use Data::Dumper;

has 'planet_data'    => (
    is      => 'ro',
    isa     => 'Any',
);

has 'planet_id' => (
    is      => 'ro',
    isa     => 'Str',
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

has 'star_id' => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_star_id',
);

has 'planet_name' => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_planet_name',
);

has 'buildings'   => (
    is        => 'ro',
    isa       => 'HashRef',
    predicate => 'has_buildings',
);

has 'get_buildings' => (
    is      => 'rw',
    isa     => 'ArrayRef[Lacuna::Building]',
    builder => '_get_buildings',
    lazy    => 1,
);

has 'get_buildings_by_name' => (
    is      => 'rw',
    isa     => 'HashRef',
    builder => '_get_buildings_by_name',
    lazy    => 1,
);

has 'get_buildings_by_id' => (
    is      => 'rw',
    isa     => 'HashRef',
    builder => '_get_buildings_by_id',
    lazy    => 1,
);

has 'population'        => ( is => 'ro', isa => 'Int' );
has 'building_count'    => ( is => 'ro', isa => 'Int' );
has 'size'              => ( is => 'ro', isa => 'Int' );
has 'orbit'             => ( is => 'ro', isa => 'Int' );
has 'alignment'         => ( is => 'ro', isa => 'Str' );
has 'type'              => ( is => 'ro', isa => 'Str' );
has 'water'             => ( is => 'ro', isa => 'Int' );
has 'ore'               => ( is => 'ro', isa => 'HashRef' );
has 'empire'            => ( is => 'ro', isa => 'HashRef', default=> sub { {} } );

has 'water_stored'      => ( is => 'ro', isa => 'Int' );
has 'energy_stored'     => ( is => 'ro', isa => 'Int' );
has 'food_stored'       => ( is => 'ro', isa => 'Int' );
has 'ore_stored'        => ( is => 'ro', isa => 'Int' );
has 'waste_stored'      => ( is => 'ro', isa => 'Int' );

has 'ore_capacity'      => ( is => 'ro', isa => 'Int' );
has 'energy_capacity'   => ( is => 'ro', isa => 'Int' );
has 'water_capacity'    => ( is => 'ro', isa => 'Int' );
has 'food_capacity'     => ( is => 'ro', isa => 'Int' );
has 'waste_capacity'    => ( is => 'ro', isa => 'Int' );


has 'water_hour'        => ( is => 'ro', isa => 'Int' );
has 'energy_hour'       => ( is => 'ro', isa => 'Int' );
has 'food_hour'         => ( is => 'ro', isa => 'Int' );
has 'ore_hour'          => ( is => 'ro', isa => 'Int' );
has 'waste_hour'        => ( is => 'ro', isa => 'Int' );

has 'happiness_hour'    => ( is => 'ro', isa => 'Int' );
has 'happiness'         => ( is => 'ro', isa => 'Int' );


around BUILDARGS => sub {
    my $orig          = shift;
    my $class         = shift;
    
    my $session       = shift;
    my $planet_id     = shift;
    my $planet_result = shift;

    my $planet_data   = $planet_result->{status}->{body} || $planet_result;
    my $buildings     = $planet_result->{buildings} || {};

    my %hash = (
        session       => $session,
        planet_id     => $planet_id,
        planet_data   => $planet_data,
        buildings     => $buildings,
        star_id       => $planet_data->{star_id},
        planet_name   => $planet_data->{name},
        alignment     => $planet_data->{empire}->{alignment} || "",
        type          => $planet_data->{type},
        ore           => $planet_data->{ore},
        empire        => $planet_data->{empire} || {},
        url           => "/body",
    );

    my $int_fields = [
        'x','y','population','building_count','size','orbit','water',
        'water_stored','energy_stored','food_stored','ore_stored','waste_stored',
        'ore_capacity','energy_capacity','water_capacity','food_capacity','waste_capacity',
        'water_hour','energy_hour','food_hour','ore_hour','waste_hour','happiness_hour','happiness'
    ];

    foreach my $field (@$int_fields) {
        $hash{$field} = $planet_data->{$field} || 0;
    }

    return $class->$orig(%hash);
};


#--------------------------------------------------------------------
#                   Public Methods
#--------------------------------------------------------------------

#-----------------------------------------------
=head2 get_building_by_name ( name )

Returns a building by it's name.  This will return the first building in the stack
and undef if the building does not exist

=head3 name

Name of the building to return

=cut

sub get_building_by_name {
    my $self      = shift;
    my $name      = shift;

    my $buildings = $self->get_buildings_by_name->{$name};

    return undef unless ($buildings);

    return $buildings->[0];
}

#-----------------------------------------------
=head2 get_building_by_id ( id )

Returns a building by it's id.

=head3 name

Name of the building to return

=cut

sub get_building_by_id {
    my $self      = shift;
    my $id        = shift;

    return $self->get_buildings_by_id->{$id};
}

#--------------------------------------------------------
=head2 get_build_queue

Returns an array ref of buildings that are in the build queue, ordered by seconds remaining

=head3 name

Name of the building to return

=cut

sub get_build_queue {
    my $self             = shift;
    my $session          = $self->session;
    my $buildings        = $self->get_buildings;

    my $build_hash = {};
    foreach my $building (@$buildings) {
        if($building->build_remaining > 0){
            $build_hash->{$building->build_remaining} = $building;
        }
    }

    my $build_queue = [];
    foreach my $seconds (sort { $a <=> $b } keys %$build_hash) {
        push @$build_queue, $build_hash->{$seconds};
    }

    return $build_queue;
}

#-----------------------------------------------
sub get_university {
    my $self = shift;
    my $buildings = $self->get_buildings_by_name;
    
    my $university = $buildings->{University};
    return undef unless $university;
    
    return $university->[0];
}

#-----------------------------------------------
=head2 rename ( name )

Rename the planet to the name passed in

=head3 name

Name to rename planet to

=cut

sub rename {
    my $self    = shift;
    my $session = $self->session;
    my $name    = shift;    
    
    my $obj     = $session->callLacuna($self->url,"rename",[$session->session_id,$self->planet_id,$name]);

    if($obj->error) {
        print "Could not rename planet to $name: ".$obj->error->message." (".$obj->error->code.")\n";
        return 0;
    }

    return 1;
}

#-----------------------------------------------
=head2 view_building_by_name ( name, id )

Returns the view of a building by it's name.  This will return the first building in the stack
and undef if the building does not exist.

=head3 name

Name of the building to return

=cut

sub view_building_by_name {
    my $self      = shift;
    my $name      = shift;

    my $session   = $self->session;

    my $buildings = $self->get_buildings_by_name->{$name};

    return undef unless ($buildings);

    my $building = $buildings->[0];

    return $building->view;
}

#-----------------------------------------------
=head2 view_building_by_id ( id )

Returns the view of a building by it's id.

=head3 name

Name of the building to return

=cut

sub view_building_by_id {
    my $self      = shift;
    my $id        = shift;

    my $session   = $self->session;

    my $building  = $self->get_buildings_by_id->{$id};

    return undef unless ($building);

    return $building->view;
}

#--------------------------------------------------------------------
#                   Private Methods
#--------------------------------------------------------------------

#-----------------------------------------------
sub _get_buildings {
    my $self          = shift;
    my $session       = $self->session;
    my $buildings     = shift || $self->buildings;

    my $session_id    = $session->session_id;
    my $planet_id     = $self->planet_id;

    my @building_arr  = ();
    foreach my $building_id (keys %{$buildings}) {
        my $building       = $buildings->{$building_id};
        my $name           = $building->{name};
        $name =~ s/\s//g;
        my $class          = "Lacuna::Building::".$name;

        my @modules    = Module::Find::findsubmod("Lacuna::Building");

        #Use the regular building module if the module dosn't exist
        unless (grep {$_ =~ $class} @modules) {
            $class = "Lacuna::Building";
        }
        else {
            # Try to load the module
            my $modulePath = $class . ".pm";
            $modulePath =~ s{::|'}{/}g;
            unless (eval { require $modulePath; 1 }) {
                print "Could not load $class because $@";
                $class = "Lacuna::Building";
            }
        }

        push(@building_arr,$class->new($session,$self,$building_id,$building));
    }

    return \@building_arr;
}

#-----------------------------------------------
sub _get_buildings_by_name {
    my $self          = shift;
    my $session       = $self->session;

    my $buildings     = $self->get_buildings;

    my $building_hash = {};
    foreach my $building (@{$buildings}) {
        my $name = $building->name;

        unless ($building_hash->{$name}) {
            $building_hash->{$name} = [$building];
            next;
        }
        push(@{$building_hash->{$name}},$building);
    }

    return $building_hash;
}

#-----------------------------------------------
sub _get_buildings_by_id {
    my $self          = shift;
    my $session       = $self->session;

    my $buildings     = $self->get_buildings;

    my $building_hash = {};
    foreach my $building (@{$buildings}) {
        $building_hash->{$building->building_id} = $building;
    }

    return $building_hash;
}


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
