package Lacuna::Empire;

=head1 LEGAL

=cut

use Moose;
use Modern::Perl;
extends ('Lacuna::WSWrapper');

use Data::Dumper;

sub BUILD {
    my $self    = shift;
    $self->url("/empire");
}


#--------------------------------------------------------------------
#                   Public Methods
#--------------------------------------------------------------------

#-----------------------------------------------
=head2 get_planet_by_name (planet_name)

Get the planet by it's name

=cut

sub get_planet_by_name {
    my $self        = shift;
    my $session     = $self->session;
    my $planet_name = shift;

    foreach my $planet (@{$session->planets}) {
        return $planet if($planet->planet_name eq $planet_name);
    }

    return undef;
}

#-----------------------------------------------
=head2 view_public_profile ( [ empire_id ] )

Helper method for retrieving public profile. This is also a pass through method.
If the first argument is an Array reference it will call the web service method
view_public_profile using the data contained in the .

=head3 empire_id

Empire to get public profile for. If no ID is passed in, public profile
is returned for the current

=cut

sub view_public_profile {
    my $self       = shift;
    my $session    = $self->session;
    my $empire_id  = shift || $session->{session}->{empire}->{id};

    my $params     = [];
    if( ref $empire_id eq "ARRAY") {
        $params = $empire_id;
    }
    else {
        push(@$params,$session->session_id,$empire_id);
    }

    my $req_obj  = $session->callLacuna($self->url,"view_public_profile",$params);

    if($req_obj->error) {
        print "Could not get empire stats: ".$req_obj->error->message." (".$req_obj->error->code.")\n";
        return undef;
    }

    return $req_obj->result;
}

#--------------------------------------------------------------------
#                   Private Methods
#--------------------------------------------------------------------


__PACKAGE__->meta->make_immutable;



=head1 NAME

Package Lacuna::Empire

=head1 DESCRIPTION

API for interacting with Lacuna Empire data.

=head1 SYNOPSIS

use Lacuna::Empire;

=head1 METHODS

These methods are available from this class:

=cut


1;

#vim:ft=perl
