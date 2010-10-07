package Lacuna::Building::ArchaeologyMinistry;

=head1 LEGAL

=cut

use Moose;
use Modern::Perl;
extends ('Lacuna::Building');

use Data::Dumper;

has 'can_search'       => ( is => 'rw', isa => 'Bool' );

sub BUILD {
    my $self    = shift;

    my $remaining  = $self->{work_remaining} || 0;
    my $can_search = ($remaining > 0) ? 0 : 1;
    $can_search    = 0 unless ($self->level > 0);

    $self->can_search($can_search);
}

#--------------------------------------------------------------------
#                   Public Methods
#--------------------------------------------------------------------

sub get_glyphs {
    my $self       = shift;
    my $session    = $self->session;
    my $session_id = $session->session_id;
    
    my $obj    = $session->callLacuna($self->url,"get_glyphs",[$session_id,$self->building_id]);

    if($obj->error) {
        print "Could not get glyphs: ".$obj->error->message." (".$obj->error->code.")\n";
        return 0;
    }

    return $obj->result->{glyphs};
}

#--------------------------------------------------------------------

sub get_ores {
    my $self       = shift;
    my $session    = $self->session;
    my $session_id = $session->session_id;
    
    my $obj    = $session->callLacuna($self->url,"get_ores_available_for_processing",[$session_id,$self->building_id]);

    if($obj->error) {
        print "Could not get ore available for recycling: ".$obj->error->message." (".$obj->error->code.")\n";
        return 0;
    }

    return $obj->result->{ore};
}

#--------------------------------------------------------------------

sub search_for_glyph {
    my $self       = shift;
    my $ore_type   = shift;
    my $session    = $self->session;
    my $session_id = $session->session_id;
    
    my $obj    = $session->callLacuna($self->url,"search_for_glyph",[$session_id,$self->building_id,$ore_type]);

    if($obj->error) {
        print "Could not search for glyph: ".$obj->error->message." (".$obj->error->code.")\n";
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
