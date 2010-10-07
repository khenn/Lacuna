package Lacuna::Building::TradeMinistry;

=head1 LEGAL

=cut

use Moose;
use Modern::Perl;
extends ('Lacuna::Building');

use Data::Dumper;

#--------------------------------------------------------------------
#                   Public Methods
#--------------------------------------------------------------------

#--------------------------------------------------------
sub add_trade {
    my $self       = shift;
    my $offer      = shift;
    my $ask        = shift;
    my $session    = $self->session;
    my $session_id = $session->session_id;
    
    my $obj        = $session->callLacuna($self->url,"add_trade",[$session_id,$self->building_id,$offer,$ask]);

    if($obj->error) {
        print "Could not view available trades: ".$obj->error->message." (".$obj->error->code.")\n";
        return 0;
    }

    return $obj->result;
}


#--------------------------------------------------------
sub view_available_trades {
    my $self       = shift;
    my $session    = $self->session;
    my $session_id = $session->session_id;

    my $obj    = $session->callLacuna($self->url,"view_available_trades",[$session_id,$self->building_id]);

    if($obj->error) {
        print "Could not view available trades: ".$obj->error->message." (".$obj->error->code.")\n";
        return 0;
    }

    return $obj->result;
}

#--------------------------------------------------------
sub view_my_trades {
    my $self       = shift;
    my $session    = $self->session;
    my $session_id = $session->session_id;

    my $obj    = $session->callLacuna($self->url,"view_my_trades",[$session_id,$self->building_id]);

    if($obj->error) {
        print "Could not my view trades: ".$obj->error->message." (".$obj->error->code.")\n";
        return 0;
    }

    return $obj->result;
}

#--------------------------------------------------------------------
#                   Private Methods
#--------------------------------------------------------------------


__PACKAGE__->meta->make_immutable;



=head1 NAME

Package Lacuna::Building::TradeMinistry

=head1 DESCRIPTION

An instance of a Trade Ministry

=head1 SYNOPSIS

use Lacuna::Building::TradeMinistry

=head1 METHODS

These methods are available from this class:

=cut


1;

#vim:ft=perl
