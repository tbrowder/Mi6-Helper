unit module Mi6::Utils;

use Mi6::Helper;

use App::Mi6;
use Text::Utils :normalize-string;
use File::Find;
use JSON::Fast;

sub action() is export {
    # usage
    say qq:to/HERE/;
    Usage: {$*PROGRAM.basename} <mode> [options...]

    CAUTION: With mode 'old=X', ensure all user code is committed before using
             the 'docs' option.
    Modes:
      new=X - Creates a new module (named X) directory by driving 'mi6', then
              changing certain files in the new repo to conform to the 'docs'
              option.  It also uses the 'provides' option for a short
              description of its main purpose. See details in the README.

      lint  - Checks for match of entries in the 'resources' dir and the
              'resources' entries in the 'META6.json' file.

      old   - *****NOT YET IMPLEMENTED*****
              Creates safe defaults for an 'mi6'-managed module in an existing
              Git Raku module repository. Reports findings and recommendations.
              See details in the README.

      version

    Options:
      dir=X      - Selects parent directory 'X' for the operations, default is '.'

      [hidden-option]
                 - If a hidden file (e.g., '.X') is provided, the program will
                   use the contents of that hidden text file for the 'provides'
                   text. The hidden file must be named the same as the module
                   name, but with hyphens in place of any colon pairs. For
                   example, the file for module 'new=Foo::Bar' is expected to
                   be '.Foo-Bar'. Note the author prefers this option for two
                   reasons: (1) it doesn't clutter the visible work space and
                   (2) it is more reliable when you make an error and want to
                   recreate the module.

      provides=X - With '=X', defines either a file 'X' or text 'X' to be used
                   in place of 'blah blah blah'. (Note No spaces are allowed in
                   a text entry: use periods ['.'] between words.)

      force      - Used with the 'old' mode: allows overwriting file 'dist.ini'
      docs       - Used with the 'old' mode: uses file 'docs/README.rakudoc'
                   to produce 'README.md'. Note extra preparation is REQUIRED
                   by the user before using it.
      debug      - For developer use
      debug2     - For developer use

    HERE
}

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

    if not ($new or $old) {
        die "FATAL: Neither 'new' nor 'old' is selected.";
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

    if $old {
        say "NOTE: Mode 'old' is not yet implemented.";
        exit;
    }

}
