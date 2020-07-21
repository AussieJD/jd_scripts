#!/usr/bin/perl

use strict;
use warnings;

# ===== Parse command line...

my($month, $year);

if (@ARGV == 2 and $ARGV[0] =~ /^\d/) {
    ($month, $year) = @ARGV;
} elsif (@ARGV == 0) {
    $| = 1;
    print "What month do you want to print: ";  chomp($month = <STDIN>);
    print "What year: ";                        chomp($year  = <STDIN>);
} else {
    die "Usage: $0 [ mm yyyy ]\n";
}
die qq{$0: "$month" isn't a month (1..12)\n}
    unless $month =~ /^\d+$/ and $month > 0 and $month <=   12;
die qq{$0: "$year" isn't a year (1..9999)\n}
    unless $month =~ /^\d+$/ and $year  > 0 and $year  <= 9999;

# ===== Read output from "cal", and reformat to a page-sized calendar...

open(CAL, '-|', 'cal', $month, $year)  or die "$0: can't pipe from cal: $!\n";

while (<CAL>) {
    s/$/                    /  if $. > 1;               # Pad partial weeks
    next  if /^\s*$/;                                   # Drop pesky blank lines

    if ($. == 1) {                                      # Month name and year
        s/^\s+//;
        print "\n", " " x ((78 - length) / 2), $_, "\n";

    } elsif (/^(..) (..) (..) (..) (..) (..) (..)/) {   # Day names or numbers
        my @days = ($1, $2, $3, $4, $5, $6, $7);

        if (/[A-Z]/) {                                  # ... Day names
            print map("|    $_    ", @days), "|\n";
        } elsif (/\d/) {                                # ... Day numbers
            print map("|       $_ ", @days), "|\n";

            foreach my $n (1..7) { print "|          " x 7, "|\n" }
        }
    }
    print "-" x 78, "\n";
}
close CAL;

