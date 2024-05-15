use Mi6::Helper;

unit module Mi6::Utils;

use App::Mi6;
use Text::Utils :normalize-string;
use File::Find;
use JSON::Fast;

sub action() is export {
    # usage
    say qq:to/HERE/;
    Usage: {$*PROGRAM.basename} <mode> [options...]

    Modes:
      new=Y  -     Creates a new module (named 'Y') in directory 'X' (default '.')
                   by executing 'mi6', then changing certain files in the new 
                   repo to conform to the 'docs' option.  It also uses the 
                   'provides' option for a short description of its main purpose. 
                   See details in the README.

      lint <dir> - Checks for match of entries in the 'resources' dir and the
                   'resources' entries in the 'META6.json' file.

    Options:
      dir=X  -     Selects directory 'X' for the operations, default is '.'

      ver    -     show version of 'mi6-helper'
    HERE
} # sub action()

sub action(@args) is export {
    # do the work

    # modes
    my $old   = 0;
    my $new   = 0;
    # options
    my $force  = 0;
    my $debug  = 0;
    my $debug2 = 0;
    my $docs   = 0;
    my $provides;
    my $provides-hidden = 1;

    # assume we are in the current working directory
    my $parent-dir   = '.';

    # other args
    my $err = 0; # track number of possible errors

    my $module-name;
    my $module-dir;

    # @*ARGS
    for @args {
        when /:i ^'old=' (\S+) / {
            $module-name = ~$0;
            ++$old
        }
        when /:i ^'new=' (\S+) / {
            $module-name = ~$0;
            ++$new;
        }
        when /:i ^f/ { ++$force }
        when /^'dir=' (\S+)/ {
            $parent-dir = ~$0;
        }
        when / ^do  / { ++$docs  }
        when / ^de2 / {
            ++$debug2;
        }
        when / ^de / {
            ++$debug;
            # check for this module's workflows file(s'
            say "DEBUG checking for expected workflow(s):";
            for "linux", "macos", "windows" -> $OS {
                my $path = ".github/workflows/$OS.yml";
                if $path {
                    say "  found path '$path'";
                }
                else {
                    say "  did NOT find '$path'";
                }
            }
            #exit;
        }
        when /^v / {
            # check for this module's version
            my $ver = get-version;
            say "version: $ver";
            exit;
        }
        when /^'provides=' (\S+)/ {
            $provides = ~$0;
            if $provides.IO.r {
                my $s = slurp $provides;
                $provides = '';
                for $s.lines {
                    $provides ~= " $_";
                }
                $provides = normalize-string $provides;
                $provides-hidden = 0;
            }
            else {
                die "FATAL: Unable to read provides file '$provides'";
            }
        }
        default {
            die "FATAL: Unknown arg '$_'.";
        }
    }

    if not ($new or $lint) {
        die "FATAL: Neither 'new' nor 'lint' is selected.";
    }

    # Take care of 'provides'
    # PRO
    if not $provides.defined {
        # info should be in a hidden file
        my $hidden = ".$module-name";
        $hidden ~~ s:g/'::'/-/;
        if $hidden.IO.r {
            my $s = slurp $hidden;
            $provides = '';
            for $s.lines {
                $provides ~= " $_";
            }
            $provides = normalize-string $provides;
            say "Getting description text from hidden file '$hidden'";
        }
        else {
            say "FATAL: Unable to find the hidden file '$hidden'.";
            my $res = prompt "Do you want to continue without it (y/N): ";
            if $res ~~ /:i ^ y/ {
                say "Okay, continuing without a 'provides' input...";
            }
            else {
                say "Aborting and exiting early.";
            }
        }
    }

    die "FATAL: Path '$parent-dir' is not a directory."
        unless $parent-dir.IO.d;
    say "Using directory '$parent-dir' as the working directory.";

    # take care of the module directory: replace '::' with '-'
    $module-dir = $module-name;
    $module-dir ~~ s:g/'::'/-/;

    if $new {
        mi6-helper-new :$parent-dir, :$module-dir, :$module-name, :$provides,
        :$debug, :$debug2;
        say qq:to/HERE/;
        Exit after 'new' mode run. See new module repo '$module-dir'
        in parent dir '$parent-dir'.
        HERE
        exit;
    }

    if $lint {
        my $lint-results = lint $parent-dir, :$debug;
        say qq:to/HERE/;
        Exit after 'lint' mode run. See results in file '$lint-results'
        in directory '$parent-dir'.
        HERE
        exit;
    }

    if $old {
        say "NOTE: Mode 'old' is not yet implemented.";
        exit;
    }
} # sub action(@args) 

sub lint($dir, :$debug, --> Str) is export {
    # must be a dir
    die "FATAL: Path '$dir' is not a directory."
        unless $dir.IO.d;

    # must have a 'resources' dir and a 'META6.json' file in the parent dir
    my $issues = ""; # to be spurted into a text file whose path name is returned
                     # to the user

    # get contents of the resources file
    my @r = find :dir("$dir/resources");

    # get contents of the META6.json file
    my %m = from-json {slurp "$dir/META6.json"};
    my @r2 = %m<resources>;

    #=====
    # Compare the two
    # the files in META6.json do not have to be under the 'resources'
    # directory but they must referenced as relative to it and exist
    # in the file tree


    #===
    #  other possible improvements
    # check the .github/workflows file(s)

    # check all 'use X' modules are in META6.json depends
    
}


