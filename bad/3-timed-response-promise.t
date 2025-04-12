use Test;

use Proc::Async::Timeout;

use Mi6::Helper;
use Mi6::Helper::Utils;

# This is to test the use of similar code in module
# 'Mi6::Helper::Utils' (thanks to @librasteve and his use of ChatGPT):
# Later, @Voldenet pointed out the current $*IN.get doesn't release.
# Putting it in another spawned process would allow it to be killed.

lives-ok {
    my $hidden = ".Foo-Bar";
    my $timeout = 5;

    my $s = Proc::Async::Timeout.new(
        'find', '/home', :enc<latin-1>
    );

    say qq:to/HERE/;
    WARNING: Unable to find the hidden file '$hidden'.
    Do you want to continue without it (y/N)?
    You have 5 seconds to decide...
    HERE

    my $in-promise = start {
        my $input = $*IN.get;
    }

    my $out-promise = Promise.in($timeout);

    my $res = await Promise.anyof($in-promise, $out-promise);
    if $res === $in-promise {

        say $res;

        =begin comment
        if $res ~~ /:i ^ y/ {
            say "Okay, continuing without a 'descrip' input...";
        }
        else {
            say "Okay, aborting and exiting early.";
        }
        =end comment
    }
    else {
        say "Too late, aborting and exiting early.";
        #exit;
    }

}, "promise check"; # end of lives-ok
