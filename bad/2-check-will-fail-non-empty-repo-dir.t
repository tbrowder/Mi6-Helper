use Test;

use File::Temp;
use File::Find;
use paths;
use File::Directory::Tree;

use Mi6::Helper;
use Mi6::Helper::Utils;

my $debug = 1;

my $tdir;
if $debug {
    $tdir = "/tmp/A";
    mkdir $tdir;
}
else {
    $tdir = tempdir;
}

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

if $debug {
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

lives-ok {
    my $proc = run "mi6-helper", "dir=$tdir", "new=Foo::Bar", :out, :err;
    my $e = $proc.exitcode;
    my $out = $proc.out.slurp(:close);
    my $err = $proc.err.slurp(:close);
    say "exitcode: $e";
    say "out: $out";
    say "err: $err";
}

exit if $debug;

dies-ok {
    run "mi6-helper", "new=Foo::Bar";
},

#rmdir $tmpdir;
