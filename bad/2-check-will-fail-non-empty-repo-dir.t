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
for @f { # is it a hidden file?
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

my ($proc);
lives-ok {
    say "Running 'mi6-helper'...";
    $proc = run "mi6-helper", "force", "dir=$tdir", "new=Foo::Bar", :out, :err;
    my $e = $proc.exitcode;
    my $out = $proc.out.slurp(:close);
    my $err = $proc.err.slurp(:close);
    say "exitcode: $e" if $debug;
    say "out: $out" if $debug;
    say "err: $err" if $debug;
}, "gen new mod Foo::Bar in dir '$tdir'";

exit if 0 or $debug;

#dies-ok {
lives-ok {
    $proc = Proc::Async.new: "mi6-helper", "new=Foo::Bar", "dir=$tdir";
    react whenever $proc.stdout.lines {
    }
    react whenever $proc.stderr.lines {
    }
    react whenever $proc.ready {
    }
    react whenever $proc.start {
    }
}

=finish

#say $proc.raku;
if $proc.err.open.so {
    say "err is still open";
}
if $proc.out.open {
    say "out is still open";
}

say $proc.out.close.so;

    #die "FATAL" unless $proc.defined;
    #die "FATAL" if $proc.exitcode ~~ /Nil/; #.defined;
    #die "FATAL" if $proc.exitcode ~~ /Nil/; #.defined;
    #die "FATAL" if $proc.exitcode != 0; #~~ /Nil/; #.defined;
#   die "FATAL" if $proc !~~ Proc;
#   die "FATAL" if $proc.exitcode != 0; #~~ /Nil/; #.defined;

#say $proc.gist;

    =begin comment
    die "FATAL" unless $e.defined;
    say "exitcode: $e";
    my $out = $proc.out.slurp(:close);
    my $err = $proc.err.slurp(:close);
    say "out: $out";
    say "err: $err";
    =end comment
#}, "no force used";

#rmdir $tmpdir;
