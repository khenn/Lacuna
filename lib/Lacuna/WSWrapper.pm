package Lacuna::WSWrapper;

use Moose;
use Modern::Perl;
use Try::Tiny;

use Data::Dumper;

has 'session'    => (
    is        => 'ro',
    isa       => 'Lacuna::Session',
    predicate => 'has_session'
);

has 'url'     => (
    is        => 'rw',
    isa       => 'Str',
    default   => ''
);

around BUILDARGS => sub {
    my $orig          = shift;
    my $class         = shift;

    my $session       = $_[0];

    if ( ref $session ne "Lacuna::Session" ) {
        return $class->$orig(@_);
    }

    return $class->$orig( session => $session );
    
};


#--------------------------------------------------------------------
#                   Public Methods
#--------------------------------------------------------------------

#-------------------------------------------------------------------

=head2 AUTOLOAD ( )

Dynamically creates functions on the fly for all the API methods in a given
Module.  This truely wraps the Web Service API into a neat little package
giving the API ultimate flexibility.  All methods from the Web Service
API will be available but can be overridden if necessary

=cut

sub AUTOLOAD {
	our $AUTOLOAD;
    return if $AUTOLOAD =~ m/::DESTROY$/;
	my $name    = (split /::/, $AUTOLOAD)[-1];	
	my $self    = shift;
    my $session = $self->session;
    my $params  = shift;
    
    try {
        my $req_obj  = $session->callLacuna($self->url,$name,$params);

        if($req_obj->error) {
            print "Web service call to $name failed: ".$req_obj->error->message." (".$req_obj->error->code.")\n";
            return undef;
        }
        return $req_obj->result;
    }
    catch {
        die "Could not call method $name on ".(ref $self)." : ".$_;
    };
}


#--------------------------------------------------------------------
#                   Private Methods
#--------------------------------------------------------------------


__PACKAGE__->meta->make_immutable;



=head1 NAME

Package Lacuna::WSWrapper

=head1 DESCRIPTION

Web Service API Wrapper for making calls to the API modules.  All modules which
are intended to call the web service should inherit from this module so that
methods can be called without having to write wrapper methods though the
use of AUTOLOAD.

=head1 SYNOPSIS

use Lacuna::WSWrapper;

=head1 METHODS

These methods are available from this class:

=cut


1;

#vim:ft=perl
