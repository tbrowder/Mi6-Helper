use Test;
use Mi6::Helper;
use App::Mi6;
use Temp::Path;

# Create some test repos:
# 1. An Mi6 dir with three types of files in addition to a 
#    standard start in order to test detecting unversioned or uncommited files.
# 2. Unmanaged modules with varying required files missing:
#
my $tdir = make-temp-dir;

my %erepos = [ 
    'Old-App' => {
        nam => 'Old::App',
        opt => '',
    },
    'New-App' => {
        nam => 'New::App',
        opt => '--zef',
    },
];

lives-ok {
    create-repos $tdir;
}

sub create-repos($tdir) {
    # mkdir "$tdir/$_" for %erepos.keys;
    for %erepos.keys -> $dir {
        my $nam = %erepos{$dir}<nam>;
        my $zef = %erepos{$dir}<opt>;
        shell "chdir $tdir; mi6 new $zef $nam";
    }
}


done-testing;

