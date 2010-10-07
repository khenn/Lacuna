package Lacuna::Building::SecurityMinistry;

=head1 LEGAL

=cut

use Moose;
use Modern::Perl;
extends ('Lacuna::Building');

use Data::Dumper;

#--------------------------------------------------------------------
#                   Public Methods
#--------------------------------------------------------------------

sub view_foreign_spies {
    my $self       = shift;
    my $session    = $self->session;
    my $session_id = $session->session_id;

    my $page_limit = 25;

    #Get the first batch of spies
    my $obj = $session->callLacuna($self->url,"view_foreign_spies",[$session_id, $self->building_id] );
    if($obj->error) {
        print "Could not view foreign spies in security ministry: ".$obj->error->message." (".$obj->error->code.")\n";
        return undef;
    }

    #say Dumper($obj);
    
    #Calculate page count so we know how many times to call the stupid thing
    #my $spy_info   = $obj->result;
    #my $page_count = int($spy_info->{spy_count}/$page_limit) + 1;

    #We already got page 1 so start on page 2
    #for (my $i = 2; $i <= $page_count; $i++) {
    #    $obj = $session->callLacuna($self->url,"view_spies",[$session_id, $self->building_id,$i] );
    #    if($obj->error) {
    #        print "Could not view spies in intelligence ministry: ".$obj->error->message." (".$obj->error->code.")\n";
    #        return undef;
    #    }
    #    push(@{$spy_info->{spies}},@{$obj->result->{spies}});
    #}

    #$self->spy_info($spy_info);
    
    return $obj;
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
