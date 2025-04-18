use Test;

use File::Temp;
use File::Find;
use File::Directory::Tree;

use Mi6::Helper;
use Mi6::Helper::Utils;

my $debug = 0;

my $tdir;
if $debug {
    $tdir = "/tmp/A";
}
else {
    $tdir = tempdir;
}

rmtree $tdir if $tdir.IO.d;
mkdir $tdir;

my $proc;
lives-ok {
    say "Running 'mi6-helper'..." if $debug;
    $proc = run "raku", "-Ilib", "bin/mi6-helper", "force", "dir=$tdir", "new=Foo::Bar"; 
    my $e = $proc.exitcode;
    is $e, 0, "exit code is $e";
}, "gen new mod Foo::Bar in dir '$tdir'";

dies-ok {
    # from @ugexe: do NOT use proc here, run only
    # this works:
    run "raku", "-Ilib", "bin/mi6-helper", "force", "dir=$tdir", "new=Foo::Bar"; 
}, "expected to fail: existing dir for gen new mod Foo::Bar in dir '$tdir'";

done-testing;

