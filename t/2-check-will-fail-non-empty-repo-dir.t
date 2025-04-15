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

rmtree $tdir if $tdir.IO ~~ :d;
mkdir $tdir;

my $proc;
lives-ok {
    say "Running 'mi6-helper'..." if $debug;
    $proc = run "raku", "-Ilib", "bin/mi6-helper", "force", "dir=$tdir", "new=Foo::Bar"; 

=begin comment
    my $e = $proc.exitcode;
   say "exitcode: $e" if $debug;
    my $out = $proc.out.slurp(:close);
    my $err = $proc.err.slurp(:close);
    say "out: $out" if $debug;
    say "err: $err" if $debug;
=end comment 
}, "gen new mod Foo::Bar in dir '$tdir'";

dies-ok {
    # from @ugexe: do NOT use proc here, run only
    run "raku", "-Ilib", "bin/mi6-helper", "force", "dir=$tdir", "new=Foo::Bar"; 
}, "fail, existing dir for gen new mod Foo::Bar in dir '$tdir'";

done-testing;

