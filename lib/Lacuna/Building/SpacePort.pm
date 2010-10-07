package Lacuna::Building::SpacePort;

=head1 LEGAL

=cut

use Moose;
extends ('Lacuna::Building');

use Data::Dumper;

has 'docked_ships'  => ( is => 'rw', isa => 'HashRef' );
has 'ships_in_transit' => ( is => 'rw', isa => 'ArrayRef' );

#--------------------------------------------------------------------
#                   Public Methods
#--------------------------------------------------------------------

#--------------------------------------------------------
sub colonize_planet {
    my $self           = shift;
    my $planet_id      = shift;
    my $session        = $self->session;
    my $session_id     = $session->session_id;
    my $from_planet_id = shift || $session->home_planet->planet_id;

    my $obj = $session->callLacuna($self->url,"send_colony_ship",[$session_id,$from_planet_id,{ body_id => $planet_id }]);

    if($obj->error) {
        print "Could not colonize planet $planet_id: ".$obj->error->message." (".$obj->error->code.")\n";
        return 0;
    }
    
    return $obj->result;
}

#--------------------------------------------------------
sub destroy_ship {
    my $self       = shift;
    my $ship_id    = shift;
    my $session    = $self->session;
    my $session_id = $session->session_id;

    my $obj = $session->callLacuna($self->url,"scuttle_ship",[$session_id,$self->building_id,$ship_id]);

    if($obj->error) {
        print "Could not destroy ship $ship_id in space port: ".$obj->error->message." (".$obj->error->code.")\n";
        return 0;
    }

    return $obj->result;
}
 
#-----------------------------------------------
=head2 get_docked_ships ( ship_type [,force])

Returns the total number of docked ships at the spaceport

=head3 ship_type

Pass in a ship type to return the total number of ships of this type

=head3 force

Forces a call to the server to get the information

=cut

sub get_docked_ships {
    my $self             = shift;
    my $return_ship_type = shift;
    my $force            = shift;

    #Get the total number of probes docked
    my $docked_ships     = $self->docked_ships;
    
    if (!$docked_ships || $force) {
        my $view             = $self->view;

        unless (defined $view) {
            print "Could not get Space Port\n";
            return 0;
        }

        $docked_ships = $view->result->{docked_ships};
        $self->docked_ships($docked_ships);
    }

    my $total_docked = 0;    

    foreach my $ship_type (keys %{$docked_ships}) {
        my $ships = $docked_ships->{$ship_type};
        if(defined $return_ship_type && $return_ship_type eq $ship_type) {
            return $ships;
        }
        $total_docked += $ships;
    }

    return $total_docked;
}

#-----------------------------------------------
=head2 get_ships_in_transit ( ship_type  )

Returns the total number of ships in transit

=head3 ship_type

Pass in a ship type to return the total number of ships of this type

=cut

sub get_ships_in_transit {
    my $self       = shift;
    my $ship_type  = shift;

    my $session    = $self->session;

    my $ships_in_transit = $self->ships_in_transit;

    unless ($ships_in_transit) {
        my $obj = $session->callLacuna($self->url,"view_ships_travelling",[$session->session_id, $self->building_id]);
    
        if($obj->error) {
            print "Could not get ships travelling in the Space Port: ".$obj->error->message." (".$obj->error->code.")\n";
            return 100000;  #Return a large number to prevent any further action.
        }

        $ships_in_transit = $obj->result->{ships_travelling};
        $self->ships_in_transit($ships_in_transit);
    }

    return scalar(@$ships_in_transit) unless ($ship_type);
    
    my $ships = 0;
    foreach my $ship_in_transit (@$ships_in_transit) {
        if($ship_in_transit->{type} eq $ship_type) {
            $ships++;
        }
    }
    return $ships;
}

#--------------------------------------------------------
sub get_available_spy_transport_ships {
    my $self       = shift;
    my $session    = $self->session;
    my $session_id = $session->session_id;

    my $obj = $session->callLacuna($self->url,"get_available_spy_ships",[$session_id,$self->planet->planet_id]);

    if($obj->error) {
        print "Could not get available ships for transport: ".$obj->error->message." (".$obj->error->code.")\n";
        return 0;
    }

    return $obj->result;

}

#--------------------------------------------------------
sub get_available_spy_fetch_ships {
    my $self       = shift;
    my $session    = $self->session;
    my $session_id = $session->session_id;

    my $obj = $session->callLacuna($self->url,"get_available_spy_ships_for_fetch",[$session_id,$self->planet->planet_id]);

    if($obj->error) {
        print "Could not get available ships for fetch".$obj->error->message." (".$obj->error->code.")\n";
        return 0;
    }

    return $obj->result;

}

#--------------------------------------------------------
sub send_probe {
    my $self       = shift;
    my $star_id    = shift;
    my $session    = $self->session;
    my $session_id = $session->session_id;
    my $planet_id  = $self->planet->planet_id;

    my $obj = $session->callLacuna($self->url,"send_probe",[$session_id,$planet_id,{ star_id => $star_id }]);

    if($obj->error) {
        print "Could not probe star $star_id: ".$obj->error->message." (".$obj->error->code.")\n";
        return 0;
    }
    
    return $obj->result;
}

#--------------------------------------------------------
sub view_ships {
    my $self       = shift;
    my $session    = $self->session;
    my $session_id = $session->session_id;

    my $obj = $session->callLacuna($self->url,"view_all_ships",[$session_id,$self->building_id]);

    if($obj->error) {
        print "Could not view ships in space port: ".$obj->error->message." (".$obj->error->code.")\n";
        return 0;
    }

    return $obj->result->{ships};
}



#--------------------------------------------------------------------
#                   Private Methods
#--------------------------------------------------------------------


__PACKAGE__->meta->make_immutable;



=head1 NAME

Package Lacuna::Building::SpacePort

=head1 DESCRIPTION

An instance of a SpacePort

=head1 SYNOPSIS

use Lacuna::Session;

=head1 METHODS

These methods are available from this class:

=cut


1;

#vim:ft=perl
