unit module Mi6::Helper::Utils;

use Mi6::Helper;

use Pod::Load;
use App::Mi6;
use Text::Utils :normalize-string, :strip-comment;
use File::Find;
use JSON::Fast;

sub mi6-help() is export {
    # usage
    say qq:to/HERE/;
    Usage: {$*PROGRAM.basename} <mode> [options...]

    Modes:
      new=Y - Creates a new module (named 'Y') in directory 'X' (default '.')
              by executing 'mi6', then changing certain files in the new
              repository to conform to the 'docs' option.  It also uses the
              'descrip' attribute for a short description of its main purpose.
              See details in the README.

    Options:
      <dir> - Selects directory <dir> for the operations, default is '.'
              (the current directory, i.e., '$*CWD').

      ver   - Shows the version of 'mi6-helper'

    NOTE    - The default directory will cause an abort if the repository home
              of this module is selected.
    HERE
} # sub mi6-help()

sub run-args($dir, @args) is export {
    # do the work

    # modes
    my $new   = 0;

    # options
    my $force  = 0;
    my $debug  = 0;
    my $d2     = 0; # debug2
    my $d3     = 0; # debug3
    my $docs   = 0;
    my $descrip;
    my $resources = 0; # add Resources subs?

    # assume we are in the current
    # working directory
    my $parent-dir = $dir; #$*CWD; # default

    # other args
    my $err = 0; # track number of possible errors

    my $module-name;
    my $module-dir;

    # @*ARGS
    for @args {
        when /:i ^'new=' (\S+) / {
            $module-name = ~$0;
            ++$new;
        }
        when /:i ^f/ { 
            ++$force;
        }
        when /^'dir=' (\S+)/ {
            $parent-dir = ~$0;
        }
        when /^ do  / { 
            ++$docs;
        }
        when /^ de / {
            ++$debug;
        }
        when /^ d2 / {
            ++$d2;
        }
        when / ^d3 / {
            ++$d3;
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
        default {
            die "FATAL: Unknown arg '$_'.";
        }
    }

    if not $new {
        die "FATAL: 'new' is not selected.";
    }

    # Take care of 'descrip'
    # PRO
    if $new and not $descrip {
        $descrip = "";
        # info should be in a hidden file
        my $hidden = ".$module-name";
        $hidden ~~ s:g/'::'/-/;
        if $hidden.IO.r {
            my $s = slurp $hidden.IO;
            for $s.lines {
                $descrip ~= " $_";
            }
            $descrip = normalize-string $descrip;
            say "Getting description text from hidden file '$hidden'";
        }
        else {
            say "FATAL: Unable to find the hidden file '$hidden'.";
            my $res = prompt "Do you want to continue without it (y/N): ";
            if $res ~~ /:i ^ y/ {
                say "Okay, continuing without a 'descrip' input...";
            }
            else {
                say "Aborting and exiting early.";
            }
        }
    }

    if $parent-dir.defined {
        unless $parent-dir.IO.d {
            die "FATAL: Path '$parent-dir' is not a directory."
        }
    }
    say "Using directory '$parent-dir'\n  as the working directory.";

    if $new {
        # take care of the module directory: replace '::' with '-'
        $module-dir = $module-name;
        $module-dir ~~ s:g/'::'/-/;

        # fail if the desired dir has ANY content:
        mi6-helper-new :$parent-dir, :$module-dir, :$module-name,
        :$debug, :$d2, :$descrip;

        say qq:to/HERE/;
        Exit after 'new' mode run. See new module repo '$module-dir'
        in parent dir '$parent-dir'.
        HERE
        exit;
    }

    =begin commment
    if $lint {
        %*ENV<RAKUDO_NO_PRECOMPILATION>=1;
        my $lint-results = lint $parent-dir, :$debug;
        my $ofil = "lint-results.txt";
        spurt $ofil, $lint-results;
        say qq:to/HERE/;
        Exit after 'lint' mode run. See results in file '$ofil'
        in directory '$parent-dir'.
        HERE
        exit;
    }

    if $old {
        say "NOTE: Mode 'old' is not yet implemented.";
        exit;
    }
    =end commment
} # sub action(@args)

sub get-zef-info($module-name, :$debug) is export {
    # Use "run" and "zef locate 'module' and 'zef list --intalled'
    # to (1) install and (2) clone the module for testing if need
    # be.
}

sub find-file-suffixes(IO::Path $dir, :%meta, :$debug --> Hash) is export {
    # TODO then add the valid names back in for more checks
    # use File::Find
    # segregate into new AND old suffixes corresponding to the four types
    #   of files

    # module distro name
    my $mname = %meta<name>;
    my $mpath = $mname;
    $mpath ~~ s/'::'/\//;
    note "DEBUG: repo name ($mname): path ($mpath)";

    #   .raku
    my @raku = find :$dir, :recurse(True), :type<file>,
                    :name(/:i '.' [raku|perl6|perl|pl6|pl|p6] $/);
    my %raku = get-basename-hash @raku;

    #   .rakumod
    my @rakumod = find :$dir, :recurse(True), :type<file>,
                        :name(/:i '.' [rakumod|pm6|pm] $/);
    my %rakumod = get-basename-hash @rakumod;

    #   .rakudoc
    my @rakudoc = find :$dir, :recurse(True), :type<file>,
                        :name(/:i '.' [rakudoc|rakupod|pod6|pod] $/);
    my %rakudoc = get-basename-hash @rakudoc;

    #   .rakutest
    my @rakutest = find :$dir, :recurse(True), :type<file>,
                        :name(/:i '.' [rakutest|t] $/);
    my %rakutest = get-basename-hash @rakutest;

    # combine the hashes into TODO
    # key: type (raku, rakudoc, rakumod, rakutest)
    # %h{$type}<basename>{$basename} = @paths

    my %h; # %h{$type}<basename>{$basename} = @paths
    for <raku rakudoc rakumod rakutest>.kv -> $i, $typ {
        with $i {
            when 0 {
                %h{$typ} = %raku;
            }
            when 1 {
                %h{$typ} = %rakudoc;
            }
            when 2 {
                %h{$typ} = %rakumod;
            }
            when 3 {
                %h{$typ} = %rakutest;
            }
        }
    }
    %h
} # sub find-file-suffixes(IO::Path $dir, :$debug --> Hash) is export {

sub get-basename-hash(@arr, :$debug --> Hash) {
    # @arr is a list of paths; from it, create a hash keyed by basename
    #   with its value an array of paths (usually one)
    my %h;
    for @arr -> $path {
        my $f = $path.IO.basename;
        if %h{$f}:exists {
            %h{$f}.push: $f;
        }
        else {
            %h{$f} = [];
            %h{$f}.push: $f;
        }
    }
    %h
} # sub get-basename-hash(@arr, :$debug --> Hash) {

=finish

sub check-changes(IO::Path $dir, :$debug --> Str) {
    say "Tom, fix this";
}

sub check-meta-vs-resources(IO::Path $dir, :$debug --> Str) {
    say "Tom, fix this";
}

sub check-repo-source(%meta, :$debug --> Str) {
    say "Tom, fix this";
}

sub check-use-depends(IO::Path $dir, :$debug --> Str) {
    say "Tom, fix this";
}

sub find-used-files($dir, %meta, :$debug --> Hash) {
    # look in: test files, raku files, module files
    # return a hash: key: type, value: list of paths
    my @fils = find :$dir, :recurse(True), :type<file>;
    my (@tests, @non-tests);
    my (%tests, %non-tests);
    my $issues = "";
    my $errs   = 0;

    for @fils {
        my $typ; # 0 = test; 1 = non-test
        when / '/t/' /   {
            @tests.push: $_;
            $typ = 0;
        }
        when / '/xt/' /  {
            @tests.push: $_;
            $typ = 0;
        }
        when / '/lib/' / {
            @non-tests.push: $_;
            $typ = 1;
        }
        when / '/bin/' / {
            @non-tests.push: $_;
            $typ = 1;
        }
        default {
            die "FATAL: Unrecognized path '$_'";
        }

        # handle the item and classify it as test or nontest
        my $f = $_;
        for $_.IO.lines -> $line is copy {
            $line = strip-comment $line;
            next if $line !~~ /\S/;
            # double-check this is NOT a double entry like
            #   use Foo; use Bar;
            if / ';' \h* (\S+) / {
                # cannot yet handle this, but could if a user wants it
                my $s = qq:to/HERE/;
                + This is a multiple statement line in file '$f':
                      $line
                  Correct it and run 'lint' again.
                HERE
                $issues ~= $s;
                next;
            }

            if /^ \h* use \h+ (\S+)
                  # may have some export tags following a space
                  [\h+ \N+ ]?
                  ';'? \h*
                $/ {
                # this should be a 'use'd module
                my $tmod = ~$0;
                if $typ == 0 {
                    %non-tests{$tmod} = 1;
                }
                elsif $typ == 1 {
                    %tests{$tmod} = 1;
                }

            }
        }

    }

    # step through the test mods to see if they are used in non-tests
    for %tests.keys {
        if %non-tests{$_}:exists {
            %non-tests{$_}:delete;
            # no need to report it
        }
    }

    # from %meta
    my %mbuild-deps = %(%meta<build-depends>);
    my %mtest-deps  = %(%meta<test-depends>);
    my %mdeps       = %(%meta<depends>);
    # ok if test dep is in deps
    my @strings;
    for %tests.keys {
        my $in-build = 0;
        my $in-tests = 0;
        my $in-deps  = 0;
        if %mbuild-deps{$_}:exists {
            ++$in-build;
        }
        if %mtest-deps{$_}:exists {
            ++$in-tests;
        }
        if %mdeps{$_}:exists {
            ++$in-deps;
        }
        if ($in-build or $in-tests) and $in-deps {
            # report and suggest delete from build or test deps
            my $s = qq:to/HERE/;
            Build- or Test-dependent module '$_' is also listed in 'depends'
            HERE
            $issues ~= $s;
        }
        elsif $in-build {
            ; # ok
        }
        elsif $in-tests {
            ; # ok
        }
        elsif $in-deps {
            ; # ok
        }
        else {
            # error, not listed in any
            my $s = qq:to/HERE/;
            ERROR: Dependent module '$_' is not listed
            HERE
            $issues ~= $s;
            ++$errs;
        }
    }

    for %non-tests.keys {
        my $in-tests = 0;
        my $in-deps  = 0;
        if %mtest-deps{$_}:exists {
            ++$in-tests
        }
        if %mdeps{$_}:exists {
            ++$in-deps
        }

        if $in-tests and $in-deps {
            # report and suggest delete from test deps
            my $s = qq:to/HERE/;
            Dependent module '$_' is also listed in 'test-depends'
            HERE
            $issues ~= $s;
        }
        elsif $in-tests {
            # error, should be in 'depends'
            my $s = qq:to/HERE/;
            ERROR: Dependent module '$_' is only listed in 'test-depends'
            HERE
            $issues ~= $s;
            ++$errs;
        }
        elsif $in-deps {
            ; # ok
        }
        else {
            # error, not listed in either
            my $s = qq:to/HERE/;
            ERROR: Dependent module '$_' is not listed
            HERE
            $issues ~= $s;
            ++$errs;
        }
    }

    # add to the report
    my $st = "Check dependent modules are listed in the META6.json file:\n";

    if $issues {
        $st ~= $issues;
    }
    else {
        $st ~= "  No issues were found.\n";

    }

    $st;

} # sub find-used-files($dir, :$debug --> Hash) {
