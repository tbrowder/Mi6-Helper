use Test;

use Mi6::Helper;
#use Temp::Path;
use File::Temp;
use Git::Status;

my ($tempdir, $res, $gs, $proc);

$tempdir = tempdir;
ok $tempdir.IO.d;

lives-ok { $gs = Git::Status.new: :directory($tempdir); }
$res = $gs.gist;
is $res, "";

{
    # home info for a fez user is in file $HOME/.fez-config.json;
    # {
    #    key : somekey
    #
    temp $*CWD = $tempdir.IO;
    temp %*ENV<HOME> = $tempdir;
    $*HOME.add().spurt: q:to/HERE/;
    user SOMEBODY
    password this-is-secret
    HERE

    my $new-mod = "Foo::Bar";
    my $moddir = "Foo::Bar";
    $moddir ~~ s/'::'/-/;
    lives-ok { $proc := run "mi6", "new", "--zef", $new-mod, :out; }
    ok $moddir.IO.d;
}


done-testing;

=finish

chdir $dir;
ok $
my $provides = 'Some text';
my $o = Mi6::Helper.new: :dir('.'), :$provides;
isa-ok $o, Mi6::Helper;

is $o.provides, $provides;

{
    chdir $dir;
    
    # create Foo::Bar 
    run <mi6 new --zef Foo::Bar>;

    # modify it
    # test for changes
}

-
done-testing;
