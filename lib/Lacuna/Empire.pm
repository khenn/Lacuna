package Lacuna::Empire;

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
    default   => '/empire'
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
=head2 view_public_data( empire_id )

View public data for the empire_id passed in

=cut

sub view_public_data {
    my $self       = shift;
    my $session    = $self->session;
    my $empire_id  = shift;

    #( session_id, [ sort_by, page_number ] )

    my $req_obj  = $session->callLacuna($self->url,"view_public_profile",[
        $session->session_id,
        $empire_id
    ]);

    if($req_obj->error) {
        print "Could not get empire stats: ".$req_obj->error->message." (".$req_obj->error->code.")\n";
        return 0;
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
