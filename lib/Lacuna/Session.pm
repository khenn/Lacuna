package Lacuna::Session;

=head1 LEGAL

=cut

use Moose;

use JSON::RPC::Common::Marshal::HTTP;
use Data::Dumper;
use LWP::UserAgent;
use DBI;
use Config::JSON;
use Modern::Perl;
use Tie::IxHash;
use DateTime;
use DateTime::Format::SQLite;

use Lacuna::Planet;

has 'config'   => ( is => 'ro');
has 'apikey'   => ( is => 'ro', isa => 'Str', predicate => 'has_apikey' );
has 'server'   => ( is => 'ro', isa => 'Str', predicate => 'has_server' );
has 'empire'   => ( is => 'ro', isa => 'Str', predicate => 'has_empire' );
has 'password' => ( is => 'ro', isa => 'Str', predicate => 'has_password' );
has 'dbh'      => ( is => 'ro', isa => 'DBI::db', predicate => 'has_dbh' );
has 'ua'       => ( is => 'ro', isa => 'LWP::UserAgent', predicate => 'has_ua' );
has 'm'        => ( is => 'ro', isa => 'JSON::RPC::Common::Marshal::HTTP', predicate => 'has_m');

has 'session'     => ( is => 'rw', isa => 'Any' );
has 'session_id'  => ( is => 'rw', isa => 'Str' );
has 'planets'     => ( is => 'rw', isa => 'ArrayRef[Lacuna::Planet]' );
has 'home_planet' => ( is => 'rw', isa => 'Lacuna::Planet' );

around BUILDARGS => sub {
    my $orig       = shift;
    my $class      = shift;

    my $configFile = shift;
    my $empire     = shift;
    my $pwd        = shift;

    my $config    = Config::JSON->new($configFile);
    my $DSN       = $config->get("dsn");
    my $DBUSER    = $config->get("dbuser");
    my $DBPASS    = $config->get("dbpass");
    my $SERVER    = $config->get("server");
    my $APIKEY    = $config->get("apikey");
    
    my %hash      = (
        dbh        => $class->_dbConnect($DSN,$DBUSER,$DBPASS),
        ua         => LWP::UserAgent->new,
        m          => JSON::RPC::Common::Marshal::HTTP->new,
        empire     => $empire,
        password   => $pwd,
        server     => $SERVER,
        apikey     => $APIKEY,
    );

    return $class->$orig(%hash);
};


sub BUILD {
    my $self    = shift;

    my $sql         = q{ select session_id, last_used from session where username = ? and server = ? };
    my ($session_id,$last_used)  = $self->quickArray($sql,[$self->empire,$self->server]);

    #Convert to dt object
    my $now           = DateTime->now;
    my $now_epoch     = $now->epoch;
    my $expires_epoch = 0;
    if($session_id) { 
        $last_used      = DateTime::Format::SQLite->parse_datetime( $last_used );
        $expires_epoch  = $last_used->add( minutes => 110 )->epoch;
    }

    my $session     = undef;

    if($expires_epoch > $now_epoch) {
        #Get full update and update session / session_id
        $session         = $self->getFullUpdate($session_id);
        die unless (defined $session);
        my $empire_id       = $session->{empire}->{id};
        my $sqlite_now = DateTime::Format::SQLite->format_datetime($now);
        $self->dbexecute(q{update session set last_used = ? where session_id = ? and empire_id = ?},[$sqlite_now,$session_id,$empire_id]);
    }
    else {
        $session         = $self->_login();
        die unless (defined $session);
        my $empire_id       = $session->{status}->{empire}->{id};
        #Save the session to the database
        $self->dbexecute(q{delete from session where empire_id = ?},[$empire_id]);
        my $sqlite_now = DateTime::Format::SQLite->format_datetime($now);
        $self->dbexecute(q{insert into session values (?,?,?,?,?,?)},[$self->session_id,$empire_id,$self->server,$self->empire,$self->password,$sqlite_now]);
    }

    my $empire  = $session->{empire};
    my $server  = $session->{server};

    my $home_planet_id  = $empire->{home_planet_id};
    my $planets         = $empire->{planets};
    
    tie my %planets, "Tie::IxHash";
    %planets            = $self->sortHash(%$planets);
    my @planet_arr      = ();

    foreach my $planet_id (keys %planets) {
        my $planet_data = $self->callLacuna("/body","get_buildings",[$self->session_id,$planet_id]);
        my $planet      = Lacuna::Planet->new($self,$planet_id,$planet_data->result);
        if($planet_id eq $home_planet_id) {
            $self->home_planet($planet);
        }
        push(@planet_arr,$planet);
    }

    $self->planets(\@planet_arr);
}

#Override new here to eval and return undef if the call to new fails.
override new => sub {
    my $session = eval { super() };
    if($@) {
        say "Session creation failed: ".$@;
        return undef;
    }
    return $session;
};

#--------------------------------------------------------------------
#                   Public Methods
#--------------------------------------------------------------------

#-----------------------------------------------
=head2 callLacuna ( module, method, params )

Makes a call to the Lacuna server using the module, method, and params.
Returns the resulting object

=head3 module

Lacuna module to call

=head3 method

Method of the module to call

=head3 params

Array ref of parameters to feed to the call.

=cut

sub callLacuna {
    my $self   = shift;
    my $module = shift;
    my $method = shift;
    my $params = shift || [];
    
    unless ($module =~ /^\//) {
        $module = "/".$module;
    }

    my $req_obj = JSON::RPC::Common::Procedure::Call->inflate({
        jsonrpc => "2.0",
        method  => $method,
        id      => "1",
        params  => $params,
    });
    
    my $m       = $self->m;

    my $req     = $m->call_to_request($req_obj);
    $req->uri($self->server.$module);
    my $res     = $self->ua->request($req);
    my $res_obj = eval { $m->response_to_result($res) };
    if($@) {
        $res_obj = bless({
            'error_class' => 'JSON::RPC::Common::Procedure::Return::Version_2_0::Error',
            'version' => '2.0',
            'error' => bless( {
                    'data' => $module,
                    'message' => 'Method returned malformed data.',
                    'code' => -32601
                }, 'JSON::RPC::Common::Procedure::Return::Version_2_0::Error' ),
            'id' => '1'
        },"JSON::RPC::Common::Procedure::Return::Version_2_0");
    }
    if($res_obj->error) {
        say Dumper($req);
        say Dumper($res_obj);
    }
    return $res_obj;
}

#-----------------------------------------------
=head2 dateToMysql ( date )

Turns a date to a mysql string ready for insert

=head3 date 

DateTime object

=cut

sub dateToMysql {
    my $self   = shift;
    my $date   = shift;
    return $date->strftime("%Y-%m-%d %H:%M:%S");
}

#-----------------------------------------------
=head2 getFullUpdate ( session_id ) 

Uses an existing session to get a full update

=head3 session_id

Id of the session to get a full update for

=cut

sub getFullUpdate {
    my $self       = shift;
    my $session_id = shift;
    
    my $res_obj = $self->callLacuna("empire","get_status",[$session_id]);
    
    if($res_obj->error) {
        print "Could not get full status for session $session_id :".$res_obj->error->message." (".$res_obj->error->code.")\n";
        return undef;
    }
    #Session is the result
    my $session = $res_obj->result;
    #Update the session in the object
    $self->session($session);
    $self->session_id($session_id);
    #Return the session
    return $session;
}

#-----------------------------------------------
=head2 toDateTime ( date [,fromMysql] )

Turns a date to a datetime object

=head3 date 

date string from lacuna server

=head3 fromMysql

convert from a mysql date instead

=cut

sub toDateTime {
    my $self      = shift;
    my $date      = shift;
    my $fromMysql = shift;
    my ($day,$month,$year,$hour,$minute,$second);

    if($fromMysql) {
        
    }
    else {
        my @parts  = split(/\s/,$date);
        $day    = $parts[0];
        $month  = $parts[1];
        $year   = $parts[2];
        my $time   = $parts[3];

        my @tparts = split(":",$time);
        $hour   = $tparts[0];
        $minute = $tparts[1];
        $second = $tparts[2];
    }

    return DateTime->new(
        year      => $year,
        month     => $month,
        day       => $day,
        hour      => $hour,
        minute    => $minute,
        second    => $second,
        time_zone => 'UTC',
    );
}

#-----------------------------------------------
=head2 dbexecute ( sql[, params, dbh] )

Executes an SQL query

=head3 sql

Query to execute

=head3 params

Array ref of parameters for the query.

=head3 dbh

optional dbh to use if you don't yet have a session

=cut

sub dbexecute {
    my $self   = shift;
    my $sql    = shift;
    my $params = shift;
    my $dbh    = $self->dbh;

    my $sth    = undef;
    unless ($sth = $dbh->prepare($sql)) {
        print "Couldn't prepare statement: ".$sql." : ". $dbh->errstr;
        return undef;
    }    
    $sth->execute(@$params);
    return $sth;
}

#-------------------------------------------------------------------

=head2 quickArray ( sql, params )

Executes a query and returns a single row of data as an array.

=head3 sql

An SQL query.

=head3 params

An array reference containing values for any placeholder params used in the SQL query.

=cut

sub quickArray {
	my $self   = shift;
	my $sql    = shift;
	my $params = shift || [];
    my $data = $self->dbh->selectrow_arrayref($sql, {}, @{ $params }) || [];
    return @{ $data };
}

#-----------------------------------------------
=head2 quickScalar ( sql[, params, dbh] )

Quickly finds and returns the scalar value of the result set

=head3 sth

Statement handler

=cut

sub quickScalar {
    my $self   = shift;
    my $sth    = $self->dbexecute(@_);
    my @data   = $sth->fetchrow_array();
    $sth->finish;
	return $data[0];
}

#-----------------------------------------------
=head2 secondsToInterval ( seconds )

Converts seconds to an interval

=head3 seconds

Seconds to convert

=cut

sub secondsToInterval {
    my $self     = shift;
    my $seconds  = shift;

    my $s        = sprintf("%02d",($seconds % 60));
    my $minutes  = sprintf("%02d",int($seconds / 60) % 60);
    my $h        = int($seconds / 3600);
    my $hours    = $h % 24;
    my $days     = int($h / 24);

    my $interval = "";
    $interval   .= "$days"."d " if ($days > 0);
    $interval   .= "$hours"."h " if ($hours > 0);
    $interval   .= "$minutes"."m ".$s."s";

    return $interval;
}

#-----------------------------------------------
=head2 sortHash ( hash )

Sorts a hash by it's values and returns the new hash

=head3 hash

Hash to sort

=cut

sub sortHash {
    my $self = shift;
	my %hash = @_;
	tie my %newHash, 'Tie::IxHash';
	for my $key ( sort { $hash{$a} cmp $hash{$b} } keys %hash ) {
		$newHash{ $key } = $hash{ $key };
	}
	return %newHash;
}

#-----------------------------------------------
=head2 sortHashByAlphaKeyValue ( key, hash )

Sorts a hash by the string value of the key specified and returns the new hash

=head3 key

Key to sort hash by

=head3 hash

Hash to sort

=cut

sub sortHashByAlphaKeyValue {
    my $self  = shift;
    my $k     = shift;
	my %hash  = @_;
	tie my %newHash, 'Tie::IxHash';

    for my $key ( sort { $hash{$a}{$k} cmp $hash{$b}{$k} } keys %hash ) {
		$newHash{ $key } = $hash{ $key };
	}
	return %newHash;
}

#-----------------------------------------------
=head2 sortHashByNumericKeyValue ( key, hash )

Sorts a hash by the numeric value of the key specified and returns the new hash

=head3 key

Key to sort hash by

=head3 hash

Hash to sort

=cut

sub sortHashByNumericKeyValue {
    my $self  = shift;
    my $k     = shift;
	my %hash  = @_;
	tie my %newHash, 'Tie::IxHash';

    for my $key ( sort { $hash{$a}{$k} <=> $hash{$b}{$k} } keys %hash ) {
		$newHash{ $key } = $hash{ $key };
	}
	return %newHash;
}


#--------------------------------------------------------------------
#                   Private Methods
#--------------------------------------------------------------------

#-----------------------------------------------
=head2 _dbConnect

Private class method which connects to lacuna database

TODO: Read mysql params from config file.

=cut

sub _dbConnect {
    my $class     = shift;
    my $DSN       = shift;
    my $DBUSER    = shift;
    my $DBPASS    = shift;

    my (undef, $driver) = DBI->parse_dsn($DSN);
    my $dbh = DBI->connect($DSN,$DBUSER,$DBPASS,{
        RaiseError => 0,
        AutoCommit => 1,
        $driver eq 'mysql' ? (mysql_enable_utf8 => 1) : (),
    });
    
    #my $dbh = DBI->connect($DSN,"","");

	unless (defined $dbh) {
		print "Couldn't connect to database: $DSN : $DBI::errstr\n";
	}

    return $dbh;
}

#-----------------------------------------------
=head2 _login (  )

Private method which logs into the empire using the empire and password stored in the object.
Returns data required to create a session.

=cut

sub _login {
    my $self     = shift;
    my $empire   = $self->empire;
    my $password = $self->password;
    my $apikey   = $self->apikey;

    my $res_obj  = $self->callLacuna("empire","login",[$empire,$password,$apikey]);

    if($res_obj->error) {
        print "Could not log into Empire ".$empire.": ".$res_obj->error->message." (".$res_obj->error->code.")\n";
        return undef;
    }

    #Session is the result
    my $session = $res_obj->result;
    #Update the session in the object
    $self->session($session);
    $self->session_id($session->{session_id});
    #Return the session
    return $session;

}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );



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
