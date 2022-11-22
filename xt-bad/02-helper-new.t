use Test;

use Ask;
use Mi6::Helper;
use File::Temp;
use App::Mi6;
use File::Directory::Tree;

# check the system for known values used for fez and mi6
my $oo          = Mi6::Helper.new: :module-name("null");
my %fez         = App::Mi6::JSON.decode(slurp "$*HOME/.fez-config.json");
my $auth        = "zef:{%fez<un>}";
my $email       = $oo.git-user-email;
my $author      = $oo.git-user-name;
my $meta-author = "$author <$email>";

my $debug = 0;

# provide a unique testing directory by test file name
my $debug-base = "debug-test";
my $debug-dir  = $debug-base ~ '/' ~ $?FILE.IO.basename;
# remove the trailing '.t*'
$debug-dir ~~ s/'.t'$//;
rmtree $debug-dir if $debug-dir.IO.d;

my ($tempdir, $res, $gs, $proc);

if not $debug {
    # normal testing
    $tempdir = tempdir;
}
else {
    # development testing: preserves the output in dir '$tempdir'
    $tempdir = mkdir $debug-dir;
}

ok $tempdir.IO.d;

{
    # home info for a fez user is in file $HOME/.fez-config.json;
    #   "un" : "SOMEBODY",
    #   "key" : "some-hash-key",

    temp $*CWD = $tempdir.IO;
    #temp %*ENV<HOME> = $tempdir;

    # DANGER DO NOT MODIFY THE USER'S ENVIRONMENT

    chdir $tempdir;

    run "touch", ".Foo-Bar";
    my $module-name = "Foo::Bar";
    my $parent-dir  = $tempdir;
    my $provides = "Provides a framistan";
    mi6-helper-new(:$parent-dir, :$module-name, :$provides, :$debug);
    my $moddir = $module-name;
    $moddir ~~ s:g/'::'/-/;
    ok $moddir.IO.d;

    # check the meta file for known values
    my %meta = App::Mi6::JSON.decode(slurp "$moddir/META6.json");
    is %meta<auth>, $auth;
    is @(%meta<authors>)[0], $author;
}

done-testing;
