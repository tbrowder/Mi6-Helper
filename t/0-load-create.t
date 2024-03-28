use Test;

use File::Temp;
use Mi6::Helper;

my ($Xstr, $Xnam, $tempdir, $o, $provides);

$tempdir = tempdir;
chdir $tempdir;

my $module-name = 'Foo::Bar-Baz';
my $module-dir  = 'Foo-Bar-Baz';
my $provides-hidden = get-hidden-name(:$module-name);
my $parent-dir = '.';

$provides = 'Some text';
$o = Mi6::Helper.new: :$parent-dir, :$module-dir, :$module-name, :$provides;
isa-ok $o, Mi6::Helper;
is $o.provides, $provides;

done-testing;
