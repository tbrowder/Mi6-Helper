#!/usr/bin/env raku

use App::Mi6;
use JSON::Fast;

my constant $SPACES = '  ';

# keys in desired order
#my @keys = <un key groups>;
#my @keys = <un key>;

say "=== JSON::Fast ===";
# the hidden fez config file
my $jfil = "$*HOME/.fez-config.json";
# the visible fez file
my $ffil = "fez-config.json";
my %fez = from-json(slurp $jfil);
my $debug = 0;
my $level = 0;
show-hash %fez, :$level, :$debug;

say "Changing 'un' and 'key' in file '$ffil'";
%fez<un>  = "SOMEBODY";
%fez<key> = "SOME SECRET";
my $fstr = App::Mi6::JSON.encode(%fez);
spurt $ffil, $fstr;


say "=== App::Mi6::JSON ===";
my %zef = App::Mi6::JSON.decode(slurp $jfil);
show-hash %zef, :$level, :$debug;

%zef<un>  = "SOMEBODY";
%zef<key> = "SOME SECRET";
#say %fez.raku;
my $zstr = App::Mi6::JSON.encode(%zef);
my $zfil = "zef-config.json";
say "Changing 'un' and 'key' in file '$zfil'";
spurt $zfil, $zstr;

sub show-str(
       $s,
  UInt :$level! is copy,
       :$debug
) is export {
    ++$level;
    my $sp = $SPACES xx $level;

    say "{$sp}    => '$s'";

}

sub show-numeric(
       $n,
  UInt :$level! is copy,
       :$debug
) is export {
    ++$level;
    my $sp = $SPACES xx $level;

    say "{$sp}    => '$n'";
}

sub show-list(
       @a,
  UInt :$level! is copy,
       :$debug
) is export {
    ++$level;
    my $sp = $SPACES xx $level;

    # operate on values
    for @a -> $v {
        #say "{$sp}Members:";
        with $v {
            when List {
                say "$sp  List value, members";
                show-list $v, :$level;
            }
            when Hash {
                say "$sp  Hash value, keys:";
                show-hash $v, :$level;
            }
            when Str {
                say "$sp  Str value";
                show-str $v, :$level;
                #say "    => '$v'";
            }
            when Numeric {
                say "$sp  Numeric value";
                show-numeric $v, :$level;
                #say "    => '$v'";
            }
            default {
                my $t = $v.^name;
                say "  Unexpected value type $t";
            }
        }
    }
}


sub show-hash(
       %h,
  UInt :$level! is copy,
       :$debug
) is export {
    ++$level;
    my $sp = $SPACES xx $level;

    my @keys = %h.keys.sort;
    for @keys -> $k {
        # operate on values
        my $v = %h{$k};
        say "{$sp}Key: $k";
        #say "{$sp}$k";
        with $v {
            when List {
                say "$sp  List value, members:";
                show-list $v, :$level;
            }
            when Hash {
                say "$sp  Hash value, keys:";
                show-hash $v, :$level;
            }
            when Str {
                say "$sp  Str value";
                show-str $v, :$level;
                #say "    => '$v'";
            }
            when Numeric {
                say "$sp  Numeric value";
                show-numeric $v, :$level;
                #say "    => '$v'";
            }
            default {
                my $t = $v.^name;
                say "  Unexpected value type $t";
            }
        }
    }
}
