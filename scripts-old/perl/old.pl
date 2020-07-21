#!/usr/bin/env perl
#
use strict;
print "hello world\n";
print 43;	
print "\n";
my $name = "fred";
print "Hello $name\n";
my $animal = "camel";
my $answer = 42;
print "$animal\n";
print "The animal is $animal\n";
print "The square of $answer is ", $answer * $answer, "\n";
print;                  # prints contents of $_ by default
my @animals = ("camel", "llama", "owl");
my @numbers = (23, 42, 69);
my @mixed   = ("camel", 42, 1.23);
print $animals[0];              # prints "camel"
print $animals[1];              # prints "llama"
print "\n";
print $mixed[$#mixed];       # last element, prints 1.23
print "\n";
print @mixed;
print "\n";
my %fruit_color = (
        apple  => "red",
        banana => "yellow",);
$fruit_color{"apple"};
my $variables = {
        scalar  =>  { 
                     description => "single item",
                     sigil => '$',
                    },
        array   =>  {
                     description => "ordered list of items",
                     sigil => '@',
                    },
        hash    =>  {
                     description => "key/value pairs",
                     sigil => '%',
                    },
    };
 print "Scalars begin with a $variables->{'scalar'}->{'sigil'}\n";
 foreach (@mixed) {
        print "This element is $_\n";
    }
 