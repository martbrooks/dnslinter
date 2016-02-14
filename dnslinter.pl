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
    [ 'fail|f',       'Report failing DNS mappings.' ],
    [ 'okay|o',       'Report okay DNS mappings.' ],
);

my $network = $opt->networks;
my $ping    = $opt->ping;
my $verbose = $opt->verbose;
my $fail    = $opt->fail;
my $okay    = $opt->okay;

my $pinger;
my $errors = 0;

eval {
    if ($ping) {
        $pinger = Net::Ping->new( 'icmp', 2 );
    }
};

if ( $@ =~ /icmp ping requires root privilege/ ) {
    fail('Ping checks require root privilege to run.');
    exit 1;
}

my @ipranges = get_netblocks();

foreach my $range (@ipranges) {
    my $block = new Net::Netmask($range);
    my $size  = $block->size;

    for my $ip ( $block->enumerate ) {

        if ( $size > 2 ) {
            next if $ip eq $block->base();
            next if $ip eq $block->broadcast();
        }

        say "Checking $ip" if $verbose;

        my $hostname = gethostbyaddr( inet_aton($ip), AF_INET );

        if ($ping) {
            if ( $pinger->ping($ip) && ( !defined $hostname ) ) {
                fail("$ip has no reverse record");
                $errors++;
                next;
            }
        }

        next unless defined $hostname;

        my @addresses = gethostbyname($hostname);
        @addresses = map { inet_ntoa($_) } @addresses[ 4 .. $#addresses ];
        my $found = scalar grep( /^$ip$/, @addresses );
        if ( $found == 0 ) {
            error("No PTR present for $ip -> $hostname.");
        } else {
            okay("PTR present for $ip -> $hostname.");
        }
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

sub fail {
    return unless $fail;
    my $message = shift;
    say "FAIL: $message";
}

sub okay {
    return unless $okay;
    my $message = shift;
    say "OK: $message";
}
