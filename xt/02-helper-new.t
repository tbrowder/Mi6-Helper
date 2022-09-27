use Test;

use Mi6::Helper;
use File::Temp;
use Git::Status;
use JSON::Fast;
use File::Directory::Tree;

my $DEBUG = 1;

# provide a unique testing directory by test file name
my $debug-base = "debug-test";
my $debug-dir  = $debug-base ~ '/' ~ $?FILE.IO.basename;
# remove the trailing '.t*'
$debug-dir ~~ s/'.t'$//;
rmtree $debug-dir if $debug-dir.IO.d;

my ($tempdir, $res, $gs, $proc);

if not $DEBUG {
    # normal testing
    $tempdir = tempdir;
}
else {
    # development testing: preserves the output in dir '$tempdir'
    $tempdir = mkdir $debug-dir;
}

ok $tempdir.IO.d;

lives-ok { $gs = Git::Status.new: :directory($tempdir); }

{
    # home info for a fez user is in file $HOME/.fez-config.json;
    #   "un" : "SOMEBODY",
    #   "key" : "some-hash-key",

    if 1 {
        temp $*CWD = $tempdir.IO;
        temp %*ENV<HOME> = $tempdir;
    }
    else {
        $*CWD = $tempdir.IO;
        %*ENV<HOME> = $tempdir;
    }

    my %fez;
    %fez<un>  = 'SOMEBODY';
    %fez<key> = 'some-hash-key';
    my $zstr  = to-json %fez;

    $*HOME.add('.fez-config.json').spurt: $zstr;

    # add pause data
    $*HOME.add('.pause').spurt: q:to/HERE/;
    user SOMEBODY
    password some-password
    HERE

    # add .gitconfig email data
    $*HOME.add('.gitconfig').spurt: q:to/HERE/;
    [user]
        name = SOMEBODY
        email = SOMEBODY@example.com
    [init]
        defaultBranch = master
    HERE

    chdir $tempdir;

    my $new-mod = "Foo::Bar";
    my $moddir = "Foo::Bar";
    $moddir ~~ s:g/'::'/-/;

    run "./bin/mi6-helper", "new=$new-mod";
    ok $moddir.IO.d;

    # check the meta file for known values
    my %meta = from-json(slurp "$moddir/META6.json");
    is %meta<auth>, "zef:SOMEBODY";
    is (%meta<authors>.shift), "SOMEBODY";
}

done-testing;
