package Lacuna::Building::IntelligenceMinistry;

=head1 LEGAL

=cut

use Moose;
extends ('Lacuna::Building');

use Data::Dumper;

has 'spy_info' => ( is => 'rw', isa => 'HashRef' );


#--------------------------------------------------------------------
#                   Public Methods
#--------------------------------------------------------------------

#-----------------------------------------------
=head2 assign_spy ( spy_id, assignment )

Get all the spies in the intelligence ministry

=head3 spy_id

Id of spy to name

=head3 assignment

Assignment to give the spy

=cut

sub assign_spy {
    my $self       = shift;
    my $spy_id     = shift;
    my $assignment = shift;

    my $session    = $self->session;
    my $session_id = $session->session_id;

    my $obj        = $session->callLacuna($self->url,"assign_spy",[$session_id,$self->building_id,$spy_id,$assignment] );

    if ($obj->error) {
        print "Could not assign spy $spy_id to $assignment: ".$obj->error->message." (".$obj->error->code.")\n";
        return 0;
    }

    return 1;
}

#-----------------------------------------------
=head2 build_spy_info ( )

View the spies in the intelligence ministry


=cut

sub build_spy_info {
    my $self       = shift;
    my $session    = $self->session;
    my $session_id = $session->session_id;
    my $page_limit = 25;

    #Get the first batch of spies
    my $obj = $session->callLacuna($self->url,"view_spies",[$session_id, $self->building_id] );
    if($obj->error) {
        print "Could not view spies in intelligence ministry: ".$obj->error->message." (".$obj->error->code.")\n";
        return undef;
    }
    
    #Calculate page count so we know how many times to call the stupid thing
    my $spy_info   = $obj->result;    
    my $page_count = int($spy_info->{spy_count}/$page_limit) + 1;

    #We already got page 1 so start on page 2
    for (my $i = 2; $i <= $page_count; $i++) {
        $obj = $session->callLacuna($self->url,"view_spies",[$session_id, $self->building_id,$i] );
        if($obj->error) {
            print "Could not view spies in intelligence ministry: ".$obj->error->message." (".$obj->error->code.")\n";
            return undef;
        }
        push(@{$spy_info->{spies}},@{$obj->result->{spies}});
    }

    $self->spy_info($spy_info);
    
    return $obj;
}

#-----------------------------------------------
=head2 get_spies ( )

Get all the spies in the intelligence ministry

=cut

sub get_spies {
    my $self       = shift;
    my $session    = $self->session;
    my $session_id = $session->session_id;

    unless ($self->spy_info) {
        $self->build_spy_info;
    }

    return $self->spy_info->{spies};
}

#-----------------------------------------------
=head2 name_spy ( spy_id, name )

Get all the spies in the intelligence ministry

=head3 spy_id

Id of spy to name

=head3 name

Name to give the spy

=cut

sub name_spy {
    my $self       = shift;
    my $spy_id     = shift;
    my $name       = shift;

    my $session    = $self->session;
    my $session_id = $session->session_id;

    my $obj        = $session->callLacuna($self->url,"name_spy",[$session_id,$self->building_id,$spy_id,$name] );

    if ($obj->error) {
        print "Could not rename spy $spy_id to $name: ".$obj->error->message." (".$obj->error->code.")\n";
        return 0;
    }

    return 1;
}

#--------------------------------------------------------------------
#                   Private Methods
#--------------------------------------------------------------------


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
