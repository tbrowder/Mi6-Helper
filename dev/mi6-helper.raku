#!/usr/bin/env raku

use lib "../lib";

use Mi6::Helper;

use JSON::Fast;
use Config::INI;
use Text::Utils :normalize-string;
use File::Find;
use Ask;

if not @*ARGS.elems {
    print qq:to/HERE/;
    Usage: {$*PROGRAM.basename} <mode> [options...]
    
    CAUTION: Ensure all user code is committed before using the 'docs' option
             with the 'old' mode.

    Modes:
        new=X - Creates a new module (named X) directory by driving 'mi6', then 
                changing certain files in the new repo to conform to the 'docs' 
                option.  It also uses the 'provides' option for a short
                description of its main purpose.

        old   - NOT YET IMPLEMENTED
                Creates safe defaults for an 'mi6'-managed module in an existing 
                Git Raku module repository. Reports findings and recommendations. 
                See details in the README.

    Options:
        dir=X       - Selects directory X for the operations, default is '.'
        force       - Allow overwriting 'dist.ini'
        docs        - Used with the 'old' mode: uses file 'docs/README.rakudoc' 
                      to produce 'README.md'. Note extra preparation is REQUIRED
                      by the user before using it.
        provides=X  - Either a file X or text X to be used in place of 'blah blah 
                      blah'. No spaces are allowed in a text entry: use periods 
                      ('.') between words.
        Debug       - For developer use

    HERE
    exit;
}

# modes
my $old   = 0; 
my $new   = 0;
# options
my $force = 0;
my $debug = 0;
my $docs  = 0;
my $provides;

# assume we are in the current working directory
my $dir   = '.';

# other args
my $err = 0; # track number of possible errors

my $new-module;
my $old-module;

for @*ARGS {
    when /:i ^o/ { ++$old   }
    when /:i ^'new=' (\S+) / { 
        $new-module = ~$0; 
        ++$new;
    }
    when /:i ^f/ { ++$force }
    when /^'dir=' (\S+)/ {
        $dir = ~$0;
    }
    when / ^d  / { ++$docs  }
    when / ^D  / { ++$debug }
    when /^'provides=' (\S+)/ {
        $provides = ~$0;
        if $provides.IO.r {
            my $s = slurp $provides;
            $provides = '';
            for $s.lines {
                $provides ~= " $_";
            }
            $provides = normalize-string $provides;
        }
        else {
            $provides ~~ s:g/'.'/ /;
        }
    }
    default {
        die "FATAL: Unknown arg '$_'.";
    }
}

die "FATAL: Path '$dir' is not a directory."
    unless $dir.IO.d;
say "Using directory '$dir' as the working directory.";

if $new {

my $debug = 1;
mi6-helper-new :$debug;

sub mi6-helper-new(:$debug) is export {

    
    # test module is "Foo::Bar"
    # method mi6-cmd(:$parent-dir, :$new-module) {
    my $o = Mi6::Helper.new;
    $o.mi6-cmd(:parent-dir($dir), :$new-module, :$debug); 

    # get the name of the module file to change and move content
    my $modpdir = $new-module;
    my $modpath = $new-module;
    $modpdir ~~ s:g/'::'/-/;
    $modpath ~~ s:g/'::'/\//;
    my $mpath = "$modpdir/lib/$modpath";
    say "DEBUG: Foo::Bar path: '$mpath'" if not $debug;

    $mpath ~= '.rakumod';

    # the file to strip pod from
    my $modstr = slurp $mpath;
    my @imodfil = $modstr.lines;
    my @omodfil;

    my @idocfil;
    my @odocfil;
   
    MODLINE: while @imodfil.elems {
        my $line = @imodfil.shift;
        if $line ~~ /^ \h* '=' begin \h+ pod/ {
            @idocfil.push: $line;
            last MODLINE;
        }
        @omodfil.push: $line;
    }
    # put ramaining content in the README.rakudoc file
    @idocfil.push($_) for @imodfil;

    # treat the README file
    for @idocfil -> $line is copy {
        if $provides and $line.contains('blah') {
            # bold module name and add new text
            $line = "B<$new-module> - $provides"
        }
        elsif $line.contains("$new-module is") {
            # bold module name
            $line ~~ s/$new-module/B<$new-module>/;
        }
        elsif $line ~~ /^ \h* Copyright/ {
            # use copyright symbol
            #  Copyright © 2021 Tom Browder
            #  Copyright E<0x00a9> 2021 Tom Browder
            $line ~~ s/Copyright/©/;
        }
        elsif $line ~~ /^ \h* This \h+ library/ {
            $line = "This library is free software; you may redistribute it or modify it under the Artistic License 2.0.";
        }
        @odocfil.push: $line;
    }
    
    # the new 'docs'directory
    mkdir "$modpdir/docs";
    # the new README.rakudoc file:
    my $docfil = "$modpdir/docs/README.rakudoc";
    my $fh = open $docfil, :w;
    $fh.say($_) for @odocfil;
    $fh.close;

    # rewrite the module file
    $fh = open $mpath, :w;
    $fh.say($_) for @omodfil;
    $fh.close;

    # mod the dist.ini file
    my $distfil = "$modpdir/dist.ini";
    my @idistfil = $distfil.IO.lines;
    my @odistfil;
    for @idistfil -> $line is copy {
        # change the README line
        #   filename = lib/Foo/Bar.rakumod
        if $line ~~ /filename \h+ '=' / {
            $line = "filename = docs/README.rakudoc";
        }
        @odistfil.push: $line;
    }
    $fh = open $distfil, :w;
    $fh.say($_) for @odistfil;
    $fh.close;
   
    # mod the META6.json file
    if $provides {
        my $jfil = "$modpdir/META6.json";
        my %j = from-json(slurp $jfil);
        #note %j.raku;
        my $desc = %j<description>;
        note "DEBUG description: '$desc'";
        %j<description> = $provides;
        my $jstr = to-json %j;
        spurt $jfil, $jstr;
    }

    say "DEBUG early exit";exit;


    # works okay for Foo::Bar (creates dir Foo-Bar)
    say "Exiting after mi6 create"; exit

} # sub mi6-helper-new

}

if $old {
    say "NOTE: Mode 'old' is not yet implemented.";
    exit;
}

say "Exit after test run"; exit;

=finish

# safety checks
my $dist-ini = 'dist.ini';
if $dist-ini.IO.f {
    say "Danger, file '$dist-ini' exists.";
    say "Checking for the 'force' option...";
    if $force {
        my $ans = ask "Are you sure you want to continue (y/N): ";
        if $ans ~~ /:i ^y/ {
            say "Continuing with mods...":
        }
        else {
            say "Continuing safely without the 'force' option...";
            $force = 0;
        }
    }
    else {
        say "Continuing safely without the 'force' option...";
    }
}

say "User is '$*USER'" if $debug;
if "$*USER" eq 'tbrowde' {
    say "User is 'tbrowde', using 'docs' option..." if $debug;
    ++$docs;
}

unless ".git".IO.d {
    say qq:to/HERE/;
    WARNING: Directory '$dir' is not a Git repository.
             No '.git' subdirectory found.
    HERE
}

say "Checking for a fez account...";;
my $fezfil = "%*ENV<HOME>/.fez-config.json";
my $feznam;
if $fezfil.IO.r {
    $feznam = %(from-json(slurp $fezfil))<un>;
    say "Found fez user name '$feznam'";
    # check for an installed fez
    my $module = 'Fez::CLI';
    try require ::($module);
    if ::($module) ~~ Failure {
        say 'You must install fez: "$ zef install fez"';
    }
}
else {
    ++$err;
    say q:to/HERE/
    No fez config file found. This program assumes
      the user has a fez account and will be publishing
      this module to the zef archives.
      You must install fez first. Then execute 
      '$ fez register' and follow the instructions.
    HERE
}

# check for META6.json and critical data
my $metafil = "$dir/META6.json";
my %meta;
if $metafil.IO.r {
    %meta = from-json $metafil.IO.slurp;
    say "META6.json' file found and read.";
}
else {
    ++$err;
    say "No 'META6.json' file found.";
}

# check for module name
my $modnam = %meta<name>:exists ?? %meta<name> !! '';
if not $modnam {
    # Can we use an App::Mi6 instance?
    # Not easily.
    ++$err;
    say "No module 'name' found in the 'META6.json' file..";
}


