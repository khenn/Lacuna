package Lacuna::Building::PlanetaryCommandCenter;

=head1 LEGAL

=cut

use Moose;
extends ('Lacuna::Building');

use Data::Dumper;

#--------------------------------------------------------------------
#                   Public Methods
#--------------------------------------------------------------------

sub view_freebies {
    my $self       = shift;
    my $session    = $self->session;
    my $session_id = $session->session_id;

    my $obj = $session->callLacuna($self->url,"view_freebies",[$session_id,$self->building_id]);

    if($obj->error) {
        print "Could not view freebies: ".$obj->error->message." (".$obj->error->code.")\n";
        return undef;
    }

    return $obj;

}


#--------------------------------------------------------------------
#                   Private Methods
#--------------------------------------------------------------------


__PACKAGE__->meta->make_immutable;



=head1 NAME

Package Lacuna::Building::Park

=head1 DESCRIPTION

An instance of a Park

=head1 SYNOPSIS

use Lacuna::Building::Park

=head1 METHODS

These methods are available from this class:

=cut


1;

#vim:ft=perl
