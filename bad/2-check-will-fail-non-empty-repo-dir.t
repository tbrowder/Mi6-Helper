use Test;

use File::Temp;
use File::Find;
use File::Directory::Tree;

use Mi6::Helper;
use Mi6::Helper::Utils;

my $debug = 1;

#my $tdir = tempdir;
my $tdir = "/tmp/A";
rmtree $tdir if $tdir.IO ~~ :d;
mkdir $tdir;

my ($proc);
lives-ok {
    say "Running 'mi6-helper'...";
    #$proc = run "mi6-helper", "force", "dir=$tdir", "new=Foo::Bar", :out, :err;
    $proc = run "raku", "-Ilib", "bin/mi6-helper", "force", "dir=$tdir", "new=Foo::Bar";
    my $e = $proc.exitcode;
   say "exitcode: $e" if $debug;
=begin comment
    my $out = $proc.out.slurp(:close);
    my $err = $proc.err.slurp(:close);
    say "out: $out" if $debug;
    say "err: $err" if $debug;
=end comment 
}, "gen new mod Foo::Bar in dir '$tdir'";

dies-ok {
    $proc = run "raku", "-Ilib", "bin/mi6-helper", "force", "dir=$tdir", "new=Foo::Bar";
}
