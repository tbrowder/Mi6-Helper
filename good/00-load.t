use Test;

use Mi6::Helper;

my $provides = 'Some text';
my $o = Mi6::Helper.new: :dir('.'), :$provides;
isa-ok $o, Mi6::Helper;

is $o.provides, $provides;

done-testing;
