#!/usr/bin/env raku

my $hidden = "descrip";

my $timeout = 5;

say qq:to/HERE/;
WARNING: Unable to find the hidden file '$hidden'.";

Do you want to continue without it (y/N)?
  You have $timeout seconds to decide...
HERE

=begin comment
my $s = 0; print "    "; while 1 { 
    sleep 1; ++$s; print('.'); if $s > 14 { say(); last; }
}
=end comment

my $in-promise = start {
    my $input = $*IN.get;
}

my $out-promise = Promise.in($timeout);
my $res = await Promise.anyof($in-promise, $out-promise);

if $res === $in-promise {
    if $res ~~ /:i ^ y/ {
        say "Okay, continuing without a 'descrip' input...";
    }
    else {
        say "Okay, aborting and exiting early.";
    }
}
else {
    say "Too late, aborting and exiting early.";
}


