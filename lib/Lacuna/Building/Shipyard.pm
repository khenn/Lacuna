package Lacuna::Building::Shipyard;

=head1 LEGAL

=cut

use Moose;
extends ('Lacuna::Building');

use Data::Dumper;

has 'buildable'   => ( is => 'rw', isa => 'HashRef' );
has 'build_queue' => ( is => 'rw', isa => 'HashRef' );


#--------------------------------------------------------------------
#                   Public Methods
#--------------------------------------------------------------------

#--------------------------------------------------------
sub get_buildable {
    my $self       = shift;
    my $force      = shift;
    my $session    = $self->session;
    my $session_id = $session->session_id;

    my $buildable  = $self->buildable;
    if(!$buildable || $force) {
        my $obj        = $session->callLacuna($self->url,"get_buildable",[$session_id,$self->building_id]);
        if($obj->error) {
            print "Could not get buildable for shipyard: ".$obj->error->message." (".$obj->error->code.")\n";
            return {};
        }
        $buildable = $obj->result;
        $self->buildable($buildable);
    }
    return $buildable;
}

#--------------------------------------------------------
sub get_buildable_ships {
    my $self = shift;
    #Get the total number of docks available
    return $self->get_buildable->{buildable};
}

#--------------------------------------------------------
sub get_docks_available {
    my $self  = shift;
    my $force = shift;
    #Get the total number of docks available
    return $self->get_buildable($force)->{docks_available} || 0;
}

#--------------------------------------------------------
sub get_queued_ships {
    my $self         = shift;
    my $ship_type    = shift;
    my $session      = $self->session;
    my $session_id   = $session->session_id;
    

    unless ($self->build_queue) {
        $self->_get_build_queue;
    }

    my $queued_ships = $self->build_queue->{ships_building} || [];
    
    if($ship_type) {
        my $array = [];
        foreach my $queued_ship (@$queued_ships) {
            push(@$array,$queued_ship) if ($queued_ship->{type} eq $ship_type);
        }
        $queued_ships = $array;
    }

    return $queued_ships;
}

#--------------------------------------------------------
sub queue_ships {
    my $self       = shift;
    my $ship_type  = shift;
    my $quantity   = shift;
    my $session    = $self->session;
    my $session_id = $session->session_id;

    return 0 unless ($quantity > 0);

    my $obj = $session->callLacuna($self->url,"build_ship",[$session_id,$self->building_id,$ship_type,$quantity]);

    if($obj->error) {
        print "Could not queue ship $ship_type: ".$obj->error->message." (".$obj->error->code.")\n";
        return 0;
    }
    
    return $obj;
}

#--------------------------------------------------------
sub get_total_queued_ships {
    my $self         = shift;
    my $ship_type    = shift;
    
    unless ($self->build_queue) {
        $self->_get_build_queue;
    }

    if($ship_type) {
        return scalar(@{$self->get_queued_ships($ship_type)});
    }
    
    return $self->build_queue->{number_of_ships_building};
}


#--------------------------------------------------------------------
#                   Private Methods
#--------------------------------------------------------------------

#--------------------------------------------------------
sub _get_build_queue {
    my $self         = shift;
    my $session      = $self->session;
    my $session_id   = $session->session_id;
    my $page_limit   = 25;

    #Get the first batch of spies
    my $obj = $session->callLacuna($self->url,"view_build_queue",[$session_id, $self->building_id] );
    if($obj->error) {
        print "Could not view build queue in shipyard ",$self->level," : ",$obj->error->message," (",$obj->error->code,")\n";
        return undef;
    }
    
    #Calculate page count so we know how many times to call the stupid thing
    my $build_queue  = $obj->result;    
    my $page_count   = int($build_queue->{number_of_ships_building}/$page_limit) + 1;

    #We already got page 1 so start on page 2
    for (my $i = 2; $i <= $page_count; $i++) {
        $obj = $session->callLacuna($self->url,"view_build_queue",[$session_id, $self->building_id,$i] );
        if($obj->error) {
            print "Could not view build queue in shipyard ",$self->level," : ",$obj->error->message," (",$obj->error->code,")\n";
            return undef;
        }
        push(@{$build_queue->{ships_building}},@{$obj->result->{ships_building}});
    }

    $self->build_queue($build_queue);
    
    return $obj
}

__PACKAGE__->meta->make_immutable;



=head1 NAME

Package Lacuna::Building::Observatory

=head1 DESCRIPTION

An instance of a Observatory

=head1 SYNOPSIS

use Lacuna::Building::Observatory;

=head1 METHODS

These methods are available from this class:

=cut


1;

#vim:ft=perl
