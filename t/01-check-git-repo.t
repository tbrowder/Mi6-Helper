use Test;
use Mi6::Helper;
use App::Mi6;

# Create some test repos:
# 1. An Mi6 dir with three types of files in addition to a standard start in order to test detecting unversioned or uncommited files.
# 2. Unmanaged modules with varying required files missing:
#
my $tdir = "t/repos";
END { if $tdir.IO.d { shell "rm -rf $tdir"; } }

my %erepos = 
    'My-App'  => 'My::App',
    'New-App' => 'New::App',
    ;
lives-ok {
    create-repos $tdir;
}

sub create-repos($tdir) {
    mkdir "$tdir/$_" for %erepos.keys;
}


done-testing;

