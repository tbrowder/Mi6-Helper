unit module Mi6::Helper::Utils;

use Mi6::Helper;
use Pod::Load;
use App::Mi6;
use Text::Utils :normalize-string, :strip-comment;
use File::Find;
use JSON::Fast;

multi sub action() is export {
    # usage
    say qq:to/HERE/;
    Usage: {$*PROGRAM.basename} <mode> [options...]

    Modes:
      new=Y - Creates a new module (named 'Y') in directory 'X' (default '.')
              by executing 'mi6', then changing certain files in the new
              repository to conform to the 'docs' option.  It also uses the
              'provides' option for a short description of its main purpose.
              See details in the README.

      lint  - Checks for match of entries in the 'resources' directory of the
              current directory (default '.') and the 'resources' entries in 
              the 'META6.json' file. Also looks for other issues.

    Options:
      dir=X - Selects directory 'X' for the operations, default is '.'

      ver   - Shows the version of 'mi6-helper'
    HERE
} # sub action()

multi sub action(@args) is export {
    # do the work

    # modes
    my $old   = 0;
    my $new   = 0;
    my $lint  = 0;
    # options
    my $force  = 0;
    my $debug  = 0;
    my $debug2 = 0;
    my $docs   = 0;
    my $provides;
    my $provides-hidden = 1;
    my $resources = 0; # add Resources subs?

    # assume we are in the current
    # working directory
    my $parent-dir = $*CWD; # default

    # other args
    my $err = 0; # track number of possible errors

    my $module-name;
    my $module-dir;

    # @*ARGS
    for @args {
        when $lint and $_.IO.d {
           $parent-dir = $_.IO.d;
        }
        when /:i ^'old=' (\S+) / {
            $module-name = ~$0;
            ++$old
        }
        when /:i ^ [l|li|lin|lint] / {
            ++$lint;
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
    if $new and not $provides.defined {
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

    if $parent-dir.defined {
        die "FATAL: Path '$parent-dir' is not a directory."
        unless $parent-dir.IO.d;
    }
    say "Using directory '$parent-dir' as the working directory.";

    if $new {
        # take care of the module directory: replace '::' with '-'
        $module-dir = $module-name;
        $module-dir ~~ s:g/'::'/-/;

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
} # sub action(@args)

sub lint($dir, :$debug, --> Str) is export {
    # must be a dir
    die "FATAL: Path '$dir' is not a directory."
        unless $dir.IO.d;

    # must have a 'resources' dir and a 'META6.json' file in the parent dir

    my $issues; # to be spurted into a text file whose path name is returned
                # to the user
    my $res;    # used to collect results from subs for the report
    my $recs;   # list of recommendation for 'best practices'
    my $report; # concatenation of $issues and $recs

    $issues = qq:to/HERE/;
    Mi6:Helper Report ({DateTime.now})

    Results of running 'mi6-helper lint <directory>'

    Directory: '{$dir.IO.basename}'
    Path:      '$dir'
    ===============================
    Issues:
    HERE

    $recs = qq:to/HERE/;
    ===============================
    Other observations:
    HERE


    # get contents of the resources file
    my @r = find :dir("$dir/resources"); # TODO type file
    if $debug {
        say "DEBUG dir resources:";
        say "  $_" for @r;
    }

    # get contents of the META6.json file
    my %meta = from-json(slurp "$dir/META6.json");
    my @r2 = @(%meta<resources>);
    if $debug {
        say "DEBUG META6.json resources:";
        say "  $_" for @r2;
    }

    #================
    # Compare the two
    # the files in META6.json do not have to be under the 'resources'
    # directory, but they must referenced as relative to it and exist
    # in the file tree
    # TODO also check all provided names include the full distro pathe
    #      to avoid the IO::String nightmare
    $res = check-meta-vs-resources :meta-res(@r), :resources(@r2);
    # TODO add to issues doc

    # other possible improvements

    #================
    # check for obsolete file names; note the hash also includes
    #   properly named files
    my %ns = find-file-suffixes $dir;
    # TODO finish this (put inside the sub?)
    for %ns.keys -> $typ { # typ: lowercase...
        my @arr = @(%ns{$typ});
        # typ: raku, rakutest, rakumod, rakudoc
        for @arr {
            # TODO ensure the paths all begin with the distro name!! (c.f. IO::String)
            when /:i '.' $typ $/ {
                # TODO notice any uppercase letters
                my $t = $_.lc;
                if $t ne $_ {
                    ; # TODO report it
                }
            }
            default {
                # TODO report the problem with the bad name
                my $s = qq:to/HERE/;
                HERE
            }
        }
    }

    #================
    # check the .github/workflows file(s) for recommended "zef test . --debug"
    $res = check-ci-tests $dir;
    # TODO add to issues doc

    # is it managed by App::Mi6
    my $is-mi6 = "$dir/dist.ini".IO.f ?? True !! False;
    # TODO add to issues doc

    #================
    # check all 'use X' modules are in META6.json depends or test-depends
    #$res = check-ci-tests $dir;
    $res = check-use-depends $dir;;
    # TODO add to issues doc

    #================
    # check Chang* for name
    unless $is-mi6 {
        $res = check-changes $dir;
        # TODO add to issues doc
    }

    #================
    # check %meta<source> for github, etc.
    $res = check-repo-source %meta;
    # TODO add to issues doc

    #================
    # check %meta<tags> for substance
    # TODO add to issues doc

    #================
    # check pod for substance
    # TODO add to issues doc

    # combine the two strings and return them
    $report = $issues ~ $recs;

} # sub lint($dir, :$debug, --> Str) is export {

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

sub check-ci-tests(IO::Path $dir, :$debug --> Str) {
    say "Tom, fix this";
} # sub check-ci-tests(IO::Path $dir, :$debug --> Str) {

sub check-changes(IO::Path $dit, :$debug --> Str) {
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
