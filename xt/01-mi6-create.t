use Test;

use Mi6::Helper;
use File::Temp;
use Git::Status;
use JSON::Fast;
use File::Directory::Tree;

# check the system for known values used for fez and mi6
my $oo          = Mi6::Helper.new: :module-name("null");
my %fez         = from-json(slurp "$*HOME/.fez-config.json");
my $auth        = "zef:{%fez<un>}";
my $email       = $oo.git-user-email;
my $author      = $oo.git-user-name;
my $meta-author = "$author <$email>";

my $debug = 0;
if 0 and $debug {
    note qq:to/HERE/;
    DEBUG:
    author: $author
    email:  $email
    auth:   zef:$auth
    HERE
    note "DEBUG early exit";exit;
}

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

ok $tempdir.IO.d, "check tempdir";

lives-ok { $gs = Git::Status.new: :directory($tempdir); }, "Git::Status";

{
    # home info for a fez user is in file $HOME/.fez-config.json;
    #   "un" : "SOMEBODY",
    #   "key" : "some-hash-key",

    temp $*CWD = $tempdir.IO;
    #temp %*ENV<HOME> = $tempdir;

    # DANGER DO NOT MODIFY THE USER'S ENVIRONMENT

    chdir $tempdir;

    my $new-mod = "Foo::Bar";
    my $moddir = $new-mod;
    $moddir ~~ s:g/'::'/-/;
    run("mi6", 'new', '--zef', $new-mod);
    ok $moddir.IO.d;

    # check the meta file for known values
    my %meta = from-json(slurp "$moddir/META6.json");
    if $debug {
        note "DEBUG:";
        for %meta.kv -> $k, $v {
            note "    key: '$k' => '$v'";
        }
    }
    is %meta<auth>, $auth;
    is @(%meta<authors>)[0], $author;
    # check some other things to be changed by helper
    #my $doc = slurp "$moddir/lib";
}

done-testing;
