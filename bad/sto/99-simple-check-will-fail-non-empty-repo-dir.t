use Test;

use App::Mi6;
use File::Temp;
use File::Find;
use File::Directory::Tree;

use lib "t/lib";
use Simple;

my $tdir = "/tmp/A";
rmtree $tdir if $tdir.IO ~~ :d;
mkdir $tdir;

my $o;
my $module-name = "Foo::Bar";
my $parent-dir  = $tdir;

lives-ok {
    $o = Simple.new: :module-name("Foo::Bar"), :parent-dir($tdir);
}, "gen new mod Foo::Bar in dir '$tdir'";

dies-ok {
    $o = Simple.new: :module-name("Foo::Bar"), :parent-dir($tdir);
}, "gen new mod Foo::Bar in dir '$tdir'";
