#!/usr/bin/env raku

use JSON::Fast;
use App::Mi6;

# keys in desired order
#my @keys = <un key groups>;
my @keys = <un key>;

say "=== JSON::Fast ===";
# the hidden fez config file
my $jfil = "$*HOME/.fez-config.json";

# the visible fez file
my $ffil = "fez-config.json";
my %fez = from-json(slurp $jfil);
for @keys -> $k {
    my $v = %fez{$k};
    if $v eq 'groups' {
        ; # ok
    }
    else {
        say "    $k => '$v'";
    }
}
say "Changing 'un' and 'key' in file '$ffil'";
%fez<un>  = "SOMEBODY";
%fez<key> = "SOME SECRET";
my $fstr = App::Mi6::JSON.encode(%fez);
spurt $ffil, $fstr;


say "=== App::Mi6::JSON ===";
my %zef = App::Mi6::JSON.decode(slurp $jfil);
for @keys -> $k {
    my $v = %zef{$k};
    if $v eq 'groups' {
        ; # ok
    }
    else {
        say "    $k => '$v'";
    }

}
%zef<un>  = "SOMEBODY";
%zef<key> = "SOME SECRET";
#say %fez.raku;
my $zstr = App::Mi6::JSON.encode(%zef);
my $zfil = "zef-config.json";
say "Changing 'un' and 'key' in file '$zfil'";
spurt $zfil, $zstr;

