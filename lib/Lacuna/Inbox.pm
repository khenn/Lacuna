package Lacuna::Inbox;

=head1 LEGAL

=cut

use Moose;

use Data::Dumper;

has 'session'    => (
    is        => 'ro',
    isa       => 'Lacuna::Session',
    predicate => 'has_session'
);

has 'url'     => (
    is        => 'ro',
    isa       => 'Str',
    default   => '/inbox'
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
=head2 send_message(recipients,subject,body)

Send a message to the account passed in

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

    my $req_obj  = $session->callLacuna($self->url,"send_message",[
        $session->session_id,
        $recipients,
        $subject,
        $body
    ]);

    if($req_obj->error) {
        print "Could not send meesage to $recipients: ".$req_obj->error->message." (".$req_obj->error->code.")\n";
        return 0;
    }

    return 1;
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
