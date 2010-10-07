package Lacuna::Building::Observatory;

=head1 LEGAL

=cut

use Moose;
extends ('Lacuna::Building');

use Modern::Perl;
use Data::Dumper;

has 'probed_stars' => ( is => 'rw', isa => 'ArrayRef' );

#--------------------------------------------------------------------
#                   Public Methods
#--------------------------------------------------------------------

#-----------------------------------------------
=head2 abandon_probe ( star_id )

Abandons the probe for the star passed in

=head3 star_id

id of the star to abandon probe of

=cut

sub abandon_probe {
    my $self       = shift;
    my $star_id    = shift;
    my $session    = $self->session;
    my $session_id = $session->session_id;

    my $obj = $session->callLacuna($self->url,"abandon_probe",[$session_id, $self->building_id, $star_id] );
    if($obj->error) {
        print "Could not abandon probed for star $star_id: ".$obj->error->message." (".$obj->error->code.")\n";
        return 0;
    }

    return 1;
}

#-----------------------------------------------
=head2 probes_allowed ( )

Returns the total number of probes allowed by the observatory

=cut

sub probes_allowed {
    my $self = shift;
    return ($self->level * 3);   
}

#-----------------------------------------------
=head2 get_probed_stars ( )

Returns the total number of stars probed for this observatory

=cut

sub get_probed_stars {
    my $self       = shift;
    my $session    = $self->session;
    my $session_id = $session->session_id;
    my $page_limit = 25;

    my $probed_stars = $self->probed_stars || [];

    unless (scalar(@$probed_stars)) {

        #Get the first batch of probed stars
        my $obj1 = $session->callLacuna($self->url,"get_probed_stars", [ $session_id, $self->building_id ] );
        if ($obj1->error) {
            print "Could not get probed stars from observatory: ".$obj1->error->message." (".$obj1->error->code.")\n";
            return [];
        }
    
        #Calculate page count so we know how many times to call the stupid thing
        $probed_stars   = $obj1->result->{stars};
        my $probe_count = $obj1->result->{star_count};    
        my $page_count  = int($probe_count/$page_limit) + 1;

        #We already got page 1 so start on page 2
        for (my $i = 2; $i <= $page_count; $i++) {
            my $obj2 = $session->callLacuna($self->url,"get_probed_stars", [ $session_id, $self->building_id, $i ] );
            if ($obj2->error) {
                print "Could not get probed stars from observatory: ".$obj2->error->message." (".$obj2->error->code.")\n";
                return [];
            }
            push(@{$probed_stars},@{$obj2->result->{stars}});
        }

        $self->probed_stars($probed_stars);
    }

    return $probed_stars;
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
