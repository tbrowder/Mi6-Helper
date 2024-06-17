#!/usr/bin/env raku

use App::Mi6;
use JSON::Fast;

# keys in desired order
my @keys = <un key groups>;
#my @keys = <un key>;

say "=== JSON::Fast ===";
# the hidden fez config file
my $jfil = "$*HOME/.fez-config.json";
# the visible fez file
my $ffil = "fez-config.json";
my %fez = from-json(slurp $jfil);
my $debug = 0;
show-hash %fez, :$debug;

say "Changing 'un' and 'key' in file '$ffil'";
%fez<un>  = "SOMEBODY";
%fez<key> = "SOME SECRET";
my $fstr = App::Mi6::JSON.encode(%fez);
spurt $ffil, $fstr;


say "=== App::Mi6::JSON ===";
my %zef = App::Mi6::JSON.decode(slurp $jfil);
show-hash %zef, :$debug;

%zef<un>  = "SOMEBODY";
%zef<key> = "SOME SECRET";
#say %fez.raku;
my $zstr = App::Mi6::JSON.encode(%zef);
my $zfil = "zef-config.json";
say "Changing 'un' and 'key' in file '$zfil'";
spurt $zfil, $zstr;

sub show-hash(%h, UInt :$level, :$debug) is export {
    my @keys = %h.keys.sort;
    for @keys -> $k {
        # operate on values
        my $v = %h{$k};
        with $v {
            say "Key: $k";
            when List {
                say "  List value ";
            } 
            when Hash {
                say "  Hash value ";
            } 
            when Str {
                say "  Str value ";
                say "    => '$v'";
            } 
            when Numeric {
                say "  Numeric value ";
                say "    => '$v'";
            } 
            default {
                my $t = $v.^name;
                say "  Unexpected value type $t";
            }
        }
    }
}

