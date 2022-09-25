use Test;

use Mi6::Helper;
use File::Temp;
use Git::Status;
use JSON::Fast;

my ($tempdir, $res, $gs, $proc);

if 1 {
    $tempdir = tempdir;
}
else {
    my $dir = "mytest";
    rmdir $dir if $dir.IO.d;
    $tempdir = mkdir "mytest";
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

    chdir $tempdir;

    my $new-mod = "Foo::Bar";
    my $moddir = "Foo::Bar";
    $moddir ~~ s/'::'/-/;
    run "mi6", "new", "--zef", $new-mod;
    ok $moddir.IO.d;

    # check the meta file for known values
    my %meta = from-json(slurp "$moddir/META6.json");
    is %meta<auth>, "zef:SOMEBODY";
}

done-testing;
