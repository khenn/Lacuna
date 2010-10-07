package Lacuna::Building::WasteRecyclingCenter;

=head1 LEGAL

=cut

use Moose;
use Modern::Perl;
extends ('Lacuna::Building');

use Data::Dumper;

has 'can_recycle'           => ( is => 'rw', isa => 'Bool' );
has 'seconds_remaining'     => ( is => 'rw', isa => 'Int' );

sub BUILD {
    my $self    = shift;

    my $remaining   = $self->{work_remaining} || 0;
    my $can_recycle = ($remaining > 0) ? 0 : 1;
    $can_recycle    = 0 unless ($self->level > 0);

    $self->can_recycle($can_recycle); 
    $self->seconds_remaining($remaining);
}

#--------------------------------------------------------------------
#                   Public Methods
#--------------------------------------------------------------------

#--------------------------------------------------------
sub max_recycle {
    my $self       = shift;
    my $view       = $self->view;

    #say Dumper($view);
    
    my $recycle    = $view->{recycle} || {};

    return $recycle->{max_recycle} || 0;
}

#--------------------------------------------------------
sub recycle {
    my $self       = shift;
    my $hash       = shift;    
    my $session    = $self->session;
    my $session_id = $session->session_id;
    
    my $ore    = $hash->{ore} || 0;
    my $energy = $hash->{energy} || 0;
    my $water  = $hash->{water} || 0;

    my $obj    = $session->callLacuna($self->url,"recycle",[$session_id,$self->building_id,$water,$ore,$energy,0]);

    if($obj->error) {
        print "Could not recycle waste: ".$obj->error->message." (".$obj->error->code.")\n";
        return 0;
    }

    return 1;
}

#--------------------------------------------------------
sub seconds_per_resource {
    my $self       = shift;
    my $view       = $self->view;
    
    my $recycle    = $view->{recycle} || {};

    return $recycle->{seconds_per_resource} || 100000;
}

#--------------------------------------------------------
sub subsidize {
    my $self       = shift;
    my $session    = $self->session;
    my $session_id = $session->session_id;

    my $obj    = $session->callLacuna($self->url,"subsidize_recycling",[$session_id,$self->building_id]);

    if($obj->error) {
        print "Could not subsidize recycling: ".$obj->error->message." (".$obj->error->code.")\n";
        return 0;
    }

    return $obj;
}


#--------------------------------------------------------------------
#                   Private Methods
#--------------------------------------------------------------------



__PACKAGE__->meta->make_immutable;



=head1 NAME

Package Lacuna::Building::WateRecyclingCenter

=head1 DESCRIPTION

An instance of a Waste Recycling Center

=head1 SYNOPSIS

use Lacuna::Building::WasteRecyclingCenter

=head1 METHODS

These methods are available from this class:

=cut


1;

#vim:ft=perl
