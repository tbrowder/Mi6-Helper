#!/usr/bin/env raku

use App::Mi6;

my $o = App::Mi6.new;

my $dir = '.';
my $new-module = "Foo::Bar";
say $o.mi6-cmd(:$dir, :$new-module, :$debug);
