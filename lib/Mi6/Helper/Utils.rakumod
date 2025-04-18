unit module Mi6::Helper::Utils;

use File::Directory::Tree;
use Pod::Load;
use App::Mi6;
use Text::Utils :normalize-string, :strip-comment;
use File::Find;
use JSON::Fast;

sub get-zef-info($module-name, :$debug) is export {
    # Use "run" and "zef locate 'module' and 'zef list --intalled'
    # to (1) install and (2) clone the module for testing if need
    # be.
}

sub find-file-suffixes(IO::Path $dir, :%meta, :$debug --> Hash) is export {
    # should be part of dlint
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

sub get-basename-hash(
    @arr,
    :$debug
      --> Hash
) is export {
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

#=finish

sub get-file-content($fnam --> Str) is export {
    %?RESOURCES{$fnam}.slurp;
}

sub get-version is export {
    $?DISTRIBUTION.meta<version>
}

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

sub cd($dir, :$debug) is export {
    temp $*CWD;
    &chdir($dir);
}


sub put-hidden-text(
    $descrip, 
    :$parent-dir!, 
    :$module-name!
    ) is export {
    my $hidden-name = get-hidden-name :$module-name;
    spurt $hidden-name.IO, $descrip;
}

sub get-hidden-name(:$module-name!) is export {
    my $s = $module-name;
    $s ~~ s:g/'::'/-/;
    $s = '.' ~ $s;
}

sub is-git-repo(
    $dir
    --> Bool
) is export {
    "$dir/.git".IO.d;
}

sub get-section(
    $section
    --> Str
) is export {
    # returns the default section desired
    if $section eq 'PruneFiles' {
        return q:to/HERE/;
        [PruneFiles]
        ; if you want to prune files when packaging, then
        ; filename = utils/tool.pl
        ;
        ; you can use Raku regular expressions
        ; match = ^ 'xt/'
        HERE
    }
    elsif $section eq 'MetaNoIndex' {
        return q:to/HERE/;
        [MetaNoIndex]
        ; if you do not want to list some files in META6.json as "provides", then
        ; filename = lib/Should/Not/List/Provides.rakumod
        HERE
    }
    elsif $section eq 'AutoScanPackages' {
        return q:to/HERE/;
        [AutoScanPackages]
        ; if you do not want mi6 to scan packages at all,
        ; but you want to manage "provides" in META6.json by yourself, then:
        ; enabled = false
        HERE
    }
    elsif $section eq 'RunBeforeBuild' {
        return q:to/HERE/;
        ; execute some commands before 'mi6 build'
        [RunBeforeBuild]
        ; %x will be replaced by $*EXECUTABLE
        ; cmd = %x -e 'say "hello"'
        ; cmd = %x -e 'say "world"'
        HERE
    }
    elsif $section eq 'RunAfterBuild' {
        return q:to/HERE/;
        ; execute some commands after `mi6 build`
        [RunAfterBuild]
        ; cmd = some shell command here
        HERE
    }
    else {
        dir "FATAL: Unknown App::Mi6 'dist.ini' section '$section'";
    }
}
