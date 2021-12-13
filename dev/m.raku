#!/usr/bin/env raku

use App::Mi6;

my $o = App::Mi6.new;

say $o.cmd('dist', '..'); #: dist;
