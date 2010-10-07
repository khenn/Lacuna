package Lacuna::Building::Park;

=head1 LEGAL

=cut

use Moose;
extends ('Lacuna::Building');

use Data::Dumper;

has 'can_throw'          => ( is => 'rw', isa => 'Bool' );
has 'seconds_remaining'  => ( is => 'rw', isa => 'Int' );

sub BUILD {
    my $self        = shift;

    my $remaining   = $self->{work_remaining} || 0;
    my $can_throw   = ($remaining > 0) ? 0 : 1;
    $can_throw      = 0 unless ($self->level > 0);

    my $result  = $self->view;
    my $party   = $result->{party} || {};

    $self->can_throw($can_throw); 
    $self->seconds_remaining($remaining);
}

#--------------------------------------------------------------------
#                   Public Methods
#--------------------------------------------------------------------

sub happiness {
    my $self       = shift;
    my $view       = $self->view;
    
    my $party      = $view->{party} || {};

    return $party->{happiness} || 0;
}

#--------------------------------------------------------

sub throw_party {
    my $self       = shift;
    my $session    = $self->session;
    my $session_id = $session->session_id;

    my $obj = $session->callLacuna($self->url,"throw_a_party",[$session_id,$self->building_id]);

    if($obj->error) {
        print "Could not throw party: ".$obj->error->message." (".$obj->error->code.")\n";
        return 0;
    }

    return 1;

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
