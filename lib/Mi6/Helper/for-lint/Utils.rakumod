unit module Mi6::Helper::Utils;

use Mi6::Helper;
use Mi6::Helper::Subs;

use Pod::Load;
use App::Mi6;
use Text::Utils :normalize-string, :strip-comment;
use File::Find;
use JSON::Fast;

our $res-info = qq:to/RESINFO/;
META6.json and /resources
===========================
In order to reliably download payloads in the /resources directory, the
module author needs to provide a list of the files in the module's
contents.

RESINFO

sub lint-help() is export {
    # usage
    print qq:to/HERE/;
    Usage: {$*PROGRAM.basename} <dir with .git subdir> [options...]

    Checks for issues in the user's selected <dir> which is expected
    to be a 'git' repository for one of the user's Raku distributions
    (commonly known as 'modules') intended for public (or local)
    distribution.

    Uses the current working directory if it has a .git subdirectory,
    otherwise you must select such a directory to continue.

    Currently checks for:
        + match of entries in the 'resources' directory of the current directory
          and the 'resources' entries in the 'META6.json' file
        + match of entries of modules listed in the 'META6.json' file and those
          'use'd in the source code
        + old Perl 6 file name suffixes:
            .t             --> .rakutest
            .pl, .p6, .pl6 --> .raku
            .pm, .pm6      --> .rakumod
            .pod, .pod6    --> .rakudoc
    HERE
    exit;
}

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

    # TODO remove lint info to new distro
      lint  - Checks various issues with the contents of the module 
              repository directory. For easier use, execute one of
              the installed programs 'dlint' or 'distro-lint'.

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
    my $old   = 0;
    my $new   = 0;
    my $lint  = 0;

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
        when /:i ^'old=' (\S+) / {
            $module-name = ~$0;
            ++$old;
        }
=begin comment
        when $lint and $_.IO.d {
           $parent-dir = $_.IO.d;
        }
        when /:i ^ [l|li|lin|lint] / {
            ++$lint;
        }
=end comment
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

=begin comment
    if not ($new or $lint) {
        die "FATAL: Neither 'new' nor 'lint' is selected.";
    }
=end comment
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

        mi6-helper-new :$parent-dir, :$module-dir, :$module-name,
        :$debug, :$d2;
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

sub lint(IO::Path:D $dir, :$debug, --> Str) is export {

    my $results = 0; # assumes NO errors;

    # must be a dir, but NOT the repo home of Mi6::Helper
    my $xdir = "Mi6-Helper";

    # if it's a published module, install it

    die "FATAL: Path '$dir' is not a directory."
        unless $dir.IO.d;

    =begin comment
    if $dir.contains($xdir) {
        die "FATAL: Path '$dir' is the repo dir for $xdir and not yet completely
            handled"
    }
    =end comment

    my $issues = ""; # a Str whose contents will be spurted into a text
                     # file whose path name is returned to the user

    $issues ~= qq:to/HERE/;
    # Checking all 'use'd modules are listed in the 'META6.json' file
    #   and vice versa.
    # types.
    #
    # Modules being used:
    HERE

    # handle the used files...
    my %meta = from-json("META6.json".IO.slurp);
    # build-depends, depends, test-depends, resources,
    my (%bmods, %dmods, %tmods, %rfils);
    my %mmods;

    # %meta< TYPE? depends> = [];
    my @bmods = @(%meta<build-depends>);
    my @tmods = @(%meta<test-depends>);
    my @dmods = @(%meta<depends>);
    my @rfils = @(%meta<resources>);
    for @bmods.kv -> $k, $mod {
        if %bmods{$mod}:exists { %bmods{$mod} += 1; }
        else                   { %bmods{$mod}  = 1; }
        # check for dups...
        if %mmods{$mod}:exists { %mmods{$mod} += 1; }
        else                   { %mmods{$mod}  = 1; }
    }
    for @tmods.kv -> $k, $mod {
        if %tmods{$mod}:exists { %tmods{$mod} += 1; }
        else                   { %tmods{$mod}  = 1; }
        # check for dups...
        if %mmods{$mod}:exists { %mmods{$mod} += 1; }
        else                   { %mmods{$mod}  = 1; }
    }
    for @dmods.kv -> $k, $mod {
        if %dmods{$mod}:exists { %dmods{$mod} += 1; }
        else                   { %dmods{$mod}  = 1; }
        # check for dups...
        if %mmods{$mod}:exists { %mmods{$mod} += 1; }
        else                   { %mmods{$mod}  = 1; }
    }

    for %mmods.kv -> $k, $v {
        if $v > 1 {
            $issues ~= "  Module $v is entered $v times in the META6.json file\n";
        }
        ++$results;
    }
    if %tmods.elems {
        $issues ~= "  Consider moving 'test-depends' modules to 'depends'\n";
        ++$results;
    }
    if %bmods.elems {
        $issues ~= "  Consider moving 'build-depends' modules to 'depends'\n";
        ++$results;
    }

    my %umods;

    # check 'use' in all files execpt those in .git or .precomp dirs
    # (includes all types of user's files)
    my @ufils = find :dir('.'), :type<file>,
                                :exclude( any(/'.precomp'/, /'.git'/) );
    if 0 and $debug {
        say "DEBUG Files found:";
        say "  $_" for @ufils;
        exit;
    }

    for @ufils -> $ufil {
        say "DEBUG: analyzing file: '$ufil'" if $debug;
        for $ufil.IO.lines.kv -> $line-num, $line {
            # ignore some line
            next if $line ~~ /' lib'/;

            if $line ~~ /^ \h* use \h* (\S+) / {
                my $mod = ~$0;
                # trim trailing ' ' or ';'
                $mod ~~ s/\,//;
                $mod ~~ s/\;//;
                $mod ~~ s/\;//;
                $mod ~~ s:g/\s//;
                next unless $mod ~~ /S+/;

                # a valid path
                my $path = $ufil;

                say "  DEBUG analyze 'use' line: '$line'"     if $debug;
                say "        results:       mod: '$mod'"      if $debug;
                say "                      path: '$path'"     if $debug;
                say "                  line-num: '$line-num'" if $debug;
                # results hash: key: module name
                #                    <path>{$path} = [ line-numbers...]
                if %umods{$mod}<path>{$path}:exists {
                    %umods{$mod}<path>{$path}.push: $line-num;
                }
                else {
                    %umods{$mod}<path>{$path} = [];
                    %umods{$mod}<path>{$path}.push: $line-num;
                }
            }
        }
    }

    for %umods.keys.sort -> $mod {
        $issues ~= "  $mod\n" if $debug;
        my @paths = %umods{$mod}<path>.keys.sort;
        for @paths -> $path {
            if not $path.IO.r {
                say "WARNING: Invalid path '$path'";
                next;
            }
            $issues ~= "    $path\n" if $debug;
            my @line-nums = @(%umods{$mod}<path>{$path});
            say "DEBUG: num mod line numbers = {@line-nums.elems}" if $debug;
            my $nstr = @line-nums.join(', ') if $debug;
            $issues ~= "      at lines: $nstr\n" if $debug;
        }
    }

    # are we missing anything
    my $mmod-absent = 0;
    for %umods.keys.sort {
        next if %mmods{$_}:exists;
        if $mmod-absent == 0 {
            $issues ~= "  Modules in source code but not in the META6.json file\n";
            ++$mmod-absent;
        }
        $issues ~= "    '$_'\n";
        ++$results;
    }

    my $umod-absent = 0;
    for %mmods.keys.sort {
        next if %umods{$_}:exists;
        if $umod-absent == 0 {
            $issues ~= "  Modules in the META6.json file but not in source code\n";
            ++$umod-absent;
        }
        $issues ~= "    '$_'\n";
        ++$results;
    }

    # done with 'use $module' analysis

    #==========================================================
    # If either a 'resources' dir exists with one or more files
    # as contents or the 'META6.json' file has one or more
    # paths listed, then report and offer fixes.

    $issues ~= qq:to/HERE/;
    # Checking mismatch between any files listed in the module's
    #   /resources directory and those in the 'META6.json' file.
    #
    # Resources mismatch:
    HERE

    my (@resfils, @testfils, @progfils, @modfils, @docfils);

    my $rec-name-change = 0;
    for @ufils -> $fil {
        if $fil ~~ /^ resources/ {
            say "DEBUG: checking ufils for /resources in path '$fil'" if 0 or $debug;
            # the path will look like: 'resources/...' so we remove it for later use
            my $f = $fil;
            $f ~~ s/resources '/' //;
            @resfils.push: $f;
        }
        =begin comment
        + old Perl 6 file name suffixes:
            .t             --> .rakutest
            .pl, .p6, .pl6 --> .raku
            .pm, .pm6      --> .rakumod
            .pod, .pod6    --> .rakudoc
        =end comment
        when $fil ~~ /:i '.' t $/ {
            # rakutest
            @testfils.push: $fil;
            ++$rec-name-change;
        }
        when $fil ~~ /:i '.' p [l|6] $/ {
            # raku
            @progfils.push: $fil;
            ++$rec-name-change;
        }
        when $fil ~~ /:i '.' pl6 $/ {
            # raku
            @progfils.push: $fil;
            ++$rec-name-change;
        }
        when $fil ~~ /:i '.' pm 6? $/ {
            # rakumod
            @modfils.push: $fil;
            ++$rec-name-change;
        }
        when $fil ~~ /:i '.' pod 6? $/ {
            # rakudoc
            @docfils.push: $fil;
            ++$rec-name-change;
        }
    }

    my $resfils-issues = ""; # used to collect results from resources check
    if not (@rfils.elems or @resfils.elems) {
        say "DEBUG: neither META6 nor /resources list any files" if $debug;
        $resfils-issues ~= "  No META6<resources> or /resources files found.\n";
    }
    else {
        if 0 or $debug {
            say "DEBUG: Either META6 or /resources list files";
        }
        # @rfils    - from META6.json
        # @resfiles - from /resources
        # hash of basenames and number of entries
        my %m; # from META6.json
        my %r; # from /resources
        for @rfils -> $path {
            # @rfils    - from META6.json
            my $bnam = $path.IO.basename;
            if %m{$bnam}<path>{$path}:exists {
                %m{$bnam}<path>{$path} += 1;
            }
            else {
                %m{$bnam}<path>{$path} = 1;
            }
        }
        for @resfils -> $path {
            # @resfils - from /resources
            my $bnam = $path.IO.basename;
            if %r{$bnam}<path>{$path}:exists {
                %r{$bnam}<path>{$path} += 1;
            }
            else {
                %r{$bnam}<path>{$path} = 1;
            }
        }

         my $err = 0;
         if %m.elems == %r.elems {
            # keys and values must match
            for %m.kv -> $k, $v {
                if %r{$k}:exists {
                    if %r{$k} == $v {
                        ; # ok
                    }
                    else {
                        ++$err;
                    }
                }
                else {
                    ++$err;
                }
            }
        }
        else {
            ++$err;
        }

        if $err {
            # report the mismatch
            if 1 or $debug {
                say "DEBUG: Showing META6 files:";
                for %m.keys.sort -> $k {
                    my $v = %m{$k};
                    say "  $k => $v";
                }
                say "DEBUG: Showing /resources files:";
                for %r.keys.sort -> $k {
                    my $v = %r{$k};
                    say "  $k => $v";
                }
             }
        }
    }

    $issues ~= $resfils-issues;

    # now check recommended file name changes
    my $filnam-issues = ""; # used to collect results from filename check

    if $rec-name-change {
        my $n = $rec-name-change;
    }

    my $recs;   # list of recommendation for 'best practices'
    my $report; # concatenation of $issues and $recs

    =begin comment
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

    =end comment

    #$report = "delayed";
    #$report;
    $issues

} # sub lint($dir, :$debug, --> Str)

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
