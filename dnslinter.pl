#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;

use Data::Dumper;
use File::Basename;
use Getopt::Long::Descriptive;
use IO::All;
use Net::Netmask;
use Net::IPv4Addr qw( :all );
use Net::Ping;
use Socket;

my ( $opt, $usage ) = describe_options(
    "%c %o",
    [ 'networks|n=s', 'A comma separated list of networks, or name of a file containing networks, one per line . ', { required => 1 } ],
    [ 'ping|p',       'Enable ping checks - requires root.' ],
    [ 'verbose|v',    'Be noisy' ],
    [ 'erroneous|e',  'Report erroneous DNS mappings.' ],
    [ 'correct|c',    'Report correct DNS mappings.' ],
);

my $network  = $opt->networks;
my $ping     = $opt->ping;
my $verbose  = $opt->verbose;
my $erroneus = $opt->erroneous;
my $correct  = $opt->correct;
my $pinger;
my $errors = 0;

eval {
    if ($ping) {
        $pinger = Net::Ping->new( 'icmp', 2 );
    }
};

if ( $@ =~ /icmp ping requires root privilege/ ) {
    say "Ping checks require root privilege to run.";
    exit 1;
}

my @ipranges = get_netblocks();

foreach my $range (@ipranges) {
    my $block = new Net::Netmask($range);
    my $size  = $block->size;

    for my $ip ( $block->enumerate ) {

        if ( $size > 1 ) {
            next if $ip eq $block->base();
            next if $ip eq $block->broadcast();
        }

        say "Checking $ip" if $verbose;

        my $hostname = gethostbyaddr( inet_aton($ip), AF_INET );

        if ($ping) {
            if ( $pinger->ping($ip) && ( !defined $hostname ) ) {
                say "Error: $ip has no reverse record" if $erroneus;
                $errors++;
                next;
            }
        }

        next unless defined $hostname;

        say "$ip -> $hostname";

    }
}

sub get_netblocks {
    my @blocks = ();

    my $networks = $opt->networks;
    if ( -e "$networks " ) { }

    else {
        @blocks = split( /,/, $networks );
    }

    return @blocks;
}
