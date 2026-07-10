#!/usr/bin/perl
use strict;
use warnings;

my $text = "Hello123";

if ($text =~ /^[A-Za-z]+$/) {
    print "Only letters\n";
}
elsif ($text =~ /^[A-Za-z]+\d+$/) {
    print "Letters followed by numbers\n";
}
else {
    print "Does not match\n";
}

# Another example using substitution
$text =~ s/\d+//;

print "After removing digits: $text\n";