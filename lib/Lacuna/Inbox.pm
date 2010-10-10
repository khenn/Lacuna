package Lacuna::Inbox;

=head1 LEGAL

=cut

use Moose;
use Modern::Perl;
extends ('Lacuna::WSWrapper');

use Data::Dumper;

sub BUILD {
    my $self    = shift;
    $self->url("/inbox");
}

#--------------------------------------------------------------------
#                   Public Methods
#--------------------------------------------------------------------

#-----------------------------------------------
=head2 send_message(recipients,subject,body)

Send a message to the account passed in.  This is also a pass through method.
If the first argument is an Array reference it will call the web service method
send_message using the data contained in the .

=head3 recipients

Comma separated string of empire names to send message to

=head3 subject

Subject of the message

=head3 body

Body of the message

=cut

sub send_message {
    my $self       = shift;
    my $session    = $self->session;
    my $recipients = shift;
    my $subject    = shift;
    my $body       = shift;

    my $params     = [];
    if( ref $recipients eq "ARRAY") {
        $params = $recipients;
    }
    else {
        push(@$params,$session->session_id,$recipients,$subject,$body);
    }

    my $req_obj  = $session->callLacuna($self->url,"send_message",$params);

    if($req_obj->error) {
        print "Could not send meesage to $recipients: ".$req_obj->error->message." (".$req_obj->error->code.")\n";
        return undef;
    }

    return $req_obj->result;
}

#--------------------------------------------------------------------
#                   Private Methods
#--------------------------------------------------------------------


__PACKAGE__->meta->make_immutable;



=head1 NAME

Package Lacuna::Session

=head1 DESCRIPTION

A Lacuna Session based on successful login

=head1 SYNOPSIS

use Lacuna::Session;

=head1 METHODS

These methods are available from this class:

=cut


1;

#vim:ft=perl
