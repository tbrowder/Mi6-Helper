#!/usr/bin/env raku

use JSON::Fast;
use App::Mi6;

say "=== JSON::Fast ===";
# the hidden fez config file
my $jfil = "$*HOME/.fez-config.json";

# the visible fez file
my $ffil = "fez-config.json";
my %fez = from-json(slurp $jfil);
for %fez.kv -> $k, $v {
    say "$k => '$v'";
}
say "Changing 'un' and 'key' in file '$ffil'";


say "=== App::Mi6::JSON ===";
my %zef = App::Mi6::JSON.decode(slurp $jfil);
for %zef.kv -> $k, $v {
    say "$k => '$v'";
}
%zef<un>  = "SOMEBODY";
%zef<key> = "SOME SECRET";
#say %fez.raku;
my $zstr = App::Mi6::JSON.encode(%zef);
my $zfil = "zef-config.json";
say "Changing 'un' and 'key' in file '$zfil'";
spurt $zfil, $zstr;

