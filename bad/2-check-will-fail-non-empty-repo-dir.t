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
    mkdir $tdir;
}
else {
    $tdir = tempdir;
}

=begin comment
if 0 {
# ensure the tdir is empty
my @d = find :dir($tdir), :type<dir>;
for @d { 
    say "DEBUG: rmdir dir '$_'" if $debug;
    rmtree $_; #.IO.d; 
}
my @f = find :dir($tdir), :type<file>;
for @f { 
    # is it a hidden file?
    my $b = $_.basename;
    if $b ~~ /^ '.' / {
        say "DEBUG: not touching hidden file '$_'" if $debug;
        next;
    }
    say "DEBUG: unlinking file '$_'" if $debug;
    unlink $_; #.IO.f; 
}
}

if 0 and $debug {
    my @f = find :dir($tdir), :type<file>;
    my $nf = @f.elems;
    say "DEBUG: early exit after cleaning tdir '$tdir'";
    say "       files remaining (if any): $nf";
    #exit;
}

if 0 {
    say "DEBUG: in dir '$tdir'";
    my $tfil = '.Foo-Bar';
    spurt $tfil, "foo";
    my $s = slurp $tfil;
    my $mdir = "$tdir/Foo-Bar".IO.absolute;
    say "tmp file '$tfil' contents: $s'";
    my @c = $mdir.IO.e ?? find(:dir($mdir)) !! ["empty"];;
    say "DEBUG: dir '$mdir' contents:";
    say "  $_" for @c;
    #say "DEBUG early exit"; exit;
}
=end comment

lives-ok {
    say "Running 'mi6-helper'...";
    my $proc = run "mi6-helper", "force", "dir=$tdir", "new=Foo::Bar", :out, :err;
    my $e = $proc.exitcode;
    my $out = $proc.out.slurp(:close);
    my $err = $proc.err.slurp(:close);
    say "exitcode: $e";
    say "out: $out";
    say "err: $err";
}, "gen new mod Foo::Bar in dir '$tdir'";

exit if 0 or $debug;

dies-ok {
    run "mi6-helper", "new=Foo::Bar";
},

#rmdir $tmpdir;
