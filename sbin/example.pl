#!/data/wre/prereqs/bin/perl -w
use strict;

$|++; # disable output buffering

use strict;
our $configFile;

BEGIN {
    unshift (@INC, "../lib");
    $configFile =  "/path/to/config.cnf";
}

use warnings;
use Modern::Perl;
use Data::Dumper;
use Lacuna::Session;
use Lacuna::Stats;

my $session      = Lacuna::Session->new($configFile,"EMPIRE NAME","PASSWORD");

my $home_planet  = $session->home_planet;

my $observatory  = $home_planet->get_building_by_name("Observatory");

my $probed_stars = $observatory->get_probed_stars;

foreach my $star (@$probed_stars) {
# ... do something

}


my $stats        = Lacuna::Stats->new($session);

say Dumper($stats->get_empire_stats);


