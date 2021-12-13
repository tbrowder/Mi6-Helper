use Test;
use App::Mi6;

use Mi6::Helper;

my $o = Mi6::Helper.new: :dir('.');
isa-ok $o, Mi6::Helper;

done-testing;
