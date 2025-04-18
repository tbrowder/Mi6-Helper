unit class Mi6::Helper;

use App::Mi6;
use JSON::Fast;
use Proc::Easier;
use File::Find;
use File::Temp;
use Text::Utils :normalize-string;
use Mi6::Helper::Utils;

has $.module-name is required; #= as known to Zef, e.g., 'Foo::Bar-Baz'
has $.module-dir;              #= as known to git, e.g., 'Foo-Bar-Baz'
has $.parent-dir;

# its top-level repo directory
# libs are determined by the '::' separators in the module name
has @.libdirs is rw;           #= 'Foo-Bar-Baz/lib/Foo/Bar-Baz.rakumod'
                               #= 'Foo-Bar-Baz/lib
                               #= 'Foo-Bar-Baz/lib/Foo
has $.libfile is rw;           #= 'Foo-Bar-Baz/lib/Foo/Bar-Baz.rakumod;

=begin comment
e.g., Foo:Bar-Baz
=end comment

has $.descrip is rw;           #= text to replace 'blah blah blah'
                               #= NOT to be confused with the META6.json's provides

has @.resources-dir-files;     #=
has @.meta-resources-files;    #=

has $.debug is rw;
has $.d3 is rw;

submethod TWEAK {
    # determine parent-dir
    if $!parent-dir.defined {
        chdir $!parent-dir;
    }
    else {
        $!parent-dir = $*CWD;
    }

    # determine directory and file names
    my @dir-parts = $!module-name.split('::');
    $!libfile = @dir-parts.pop; #= 'lib/Foo/Bar-Baz.rakumod;
    @!libdirs = @dir-parts;

    # use App::Mi6 to create the module to modify
    # take care of the module directory: replace '::' with '-'
    $!module-dir = $!module-name;
    $!module-dir ~~ s:g/'::'/-/;

    # Note: 'mi6' will abort if the $module-name or $module-dir
    #  (as needed) exists. Do NOT check for contents with
    #  'mi6-helper'! However, a hidden file is okay (if used).
    die "FATAL: Directory '$!module-dir' already exists"
        if $!module-dir.IO.d;

    cmd "mi6 new --zef $!module-name";

    self.libdirs = find :dir($!module-dir), :type<dir>;
    my $libdir = "$!module-dir/lib";
    self.libfile = find :dir($libdir), :type<file>;

    # where do we look for the hidden file?
    my $hfil = get-hidden-name :module-name($!module-name);
    if $hfil.IO.f {
        self.descrip = slurp $hfil.IO;
    }
    self.build-mi6-helper;
}

=begin comment
method mi6-new-cmd(:$parent-dir!, :$module-dir!, :$module-name!, :$debug, :$debug2) {
    chdir $parent-dir;
    # Note: 'mi6' will abort if the $module-name or $module-dir
    #  (as needed) exists. Do NOT check for contents with
    #  'mi6-helper'! However, a hidden is okay (if used).

    cmd "mi6 new --zef $module-name";
    self.libdirs = find :dir($module-dir), :type<dir>;
    my $libdir = "$module-dir/lib";
    self.libfile = find :dir($libdir), :type<file>;
}
=end comment

method git-status {
    # branch and working tree status
    cmd("git status -b -s").out.chomp
}

method git-user-email {
    cmd("git config --get --global user.email").out.chomp
}

method git-user-name {
    cmd("git config --get --global user.name").out.chomp
}

multi method is-git-repo($dir) {
    "$dir/.git".IO.d;
}

multi method is-git-dir($dir) {
    "$dir/.git".IO.d;
}

multi method is-mi6-repo($dir) {
    "$dir/dist.ini".IO.f;
}

# this should be a private method called in TWEAK
#sub mi6-helper-new(
method build-mi6-helper(
    #:$parent-dir!, :$module-dir, :$module-name!, :$descrip,
    #:$debug, :$debug2, :$d2, :$d3, :$force,
    ) {

    # test module is "Foo::Bar"
    # method mi6-cmd(:$parent-dir, :$module-name) {
    # we use the output of the resulting files to modify
    # and use for the revisions
    #my $o = Mi6::Helper.new: :$module-name;

    =begin comment
    # this is done in TWEAK now
    $o.mi6-new-cmd(:$parent-dir, :$module-dir, :$module-name, :$debug, :$debug2,
                   :$descrip);
    =end comment

# TODO all below goes in TWEAK!!
    # get the name of the module file to change and move content
    my $modpdir = $!module-name;
    my $modpath = $!module-name;
    $modpdir ~~ s:g/'::'/-/;
    $modpath ~~ s:g/'::'/\//;
    my $mpath = "$modpdir/lib/$modpath";
    #say "DEBUG: Foo::Bar path: '$mpath'" if $debug;

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
    # put remaining content in the README.rakudoc file
    @idocfil.push($_) for @imodfil;

    # treat the README file
    for @idocfil -> $line is copy {
        if $line.contains('blah') {
            if $!descrip {
                # bold module name and add new text
                $line = "B<$!module-name> - $!descrip"
            }
            else {
                $!descrip = "blah blah blah"; # default from 'mi6'
                # bold module name only
                $line = "B<$!module-name> - blah blah blah"
            }
        }
        elsif $line.contains("$!module-name is") {
            # bold module name
            my $tnam = $!module-name;
            $line ~~ s/$tnam/B<$tnam>/;
        }
        elsif $line ~~ /^ \h* Copyright/ {
            # use copyright symbol
            #  Copyright © 2023 Tom Browder
            #  Copyright E<0x00a9> 2023 Tom Browder
            $line ~~ s/Copyright/©/;
        }
        elsif $line ~~ /^ \h* This \h+ library/ {
            $line = q:to/HERE/.lines.words.join(" ");

            This library is free software; you may
            redistribute it or modify it under the
            Artistic License 2.0.

            HERE

        }
        @odocfil.push: $line;
    }

    # the new test file
    mkdir "$modpdir/t";
    # create the test file for the base module
    my $testfil = "$modpdir/t/0-load-test.rakutest";
    my $fh = open $testfil, :w;
    $fh.print: qq:to/HERE/;
    use Test;

    my @modules = <
        $!module-name
    >;

    plan \@modules.elems;

    for \@modules -> \$m \{
        use-ok \$m, \"Module '\$m' used okay\";
    }
    HERE
    $fh.close;

    # the new 'docs' directory
    mkdir "$modpdir/docs";
    # the new README.rakudoc file:
    my $docfil = "$modpdir/docs/README.rakudoc";
    $fh = open $docfil, :w;
    $fh.say($_) for @odocfil;
    $fh.close;

    # rewrite the module file
    $fh = open $mpath, :w;
    $fh.say($_) for @omodfil;
    $fh.close;

    # use the Mi6-Helper/.github/workflows/*.yml files as I've updated them

    my $Lf = "linux.yml";
    my $Mf = "macos.yml";
    my $Wf = "windows.yml";

    my $Lstr = get-file-content($Lf);
    my $Mstr = get-file-content($Mf);
    my $Wstr = get-file-content($Wf);

    #note "DEBUG: \$Lstr = $Lstr";

    my $Lfil = "$modpdir/.github/workflows/$Lf";
    my $Mfil = "$modpdir/.github/workflows/$Mf";
    my $Wfil = "$modpdir/.github/workflows/$Wf";

    spurt $Lfil, $Lstr;
    spurt $Mfil, $Mstr;
    spurt $Wfil, $Wstr;

    # remove the existing test.yml file
    my $unwanted = "$modpdir/.github/workflows/test.yml";
    unlink $unwanted if $unwanted.IO.e;

    # remove the old test file (source is a mystery, but probably from mi6)
    $unwanted = "$modpdir/t/01-basic.rakutest";
    unlink $unwanted if $unwanted.IO.e;

    # mod the dist.ini file. add ALL optional sections recognized by App::Mi6

    my $distfil  = "$modpdir/dist.ini";
    my @idistfil = $distfil.IO.lines;
    my @odistfil;
    # all 9 known sections
    my %sections = [
        ReadmeFromPod => False, # not normally optional
        UploadToZef => False,   # not normally optional
        UploadToCPAN => False,  # not normally optional
        Badges => False,        # not normally optional
        PruneFiles => False,
        MetaNoIndex => False,
        AutoScanPackages => False,
        RunBeforeBuild => False,
        RunAfterBuild => False,
    ];
    # optional sections we will add
    my %opt-sections = set <
        PruneFiles
        MetaNoIndex
        AutoScanPackages
        RunBeforeBuild
        RunAfterBuild
    >;
    my @opt-sections = <
        PruneFiles
        MetaNoIndex
        AutoScanPackages
        RunBeforeBuild
        RunAfterBuild
    >;

    for @idistfil -> $line is copy {
        # track sections used
        if $line ~~ /'[' (\S\+) ']'/ {
            my $section = ~$0;
            if %sections{$section}:exists {
                %sections{$section} = True;
            }
            else {
                die "FATAL: Unknown App::Mi6 dist.ini section '$section'";
            }
        }
        # change the README line
        #   filename = lib/Foo/Bar.rakumod
        if $line ~~ /filename \h+ '=' / {
            $line = "filename = docs/README.rakudoc";
            @odistfil.push: $line;
            next;
        }
        elsif $line ~~ /provider \h+ '=' / {
            $line = "provider = github-actions/linux.yml";
            @odistfil.push: $line;
            $line = "provider = github-actions/macos.yml";
            @odistfil.push: $line;
            $line = "provider = github-actions/windows.yml";
            @odistfil.push: $line;
            next;
        }
        @odistfil.push: $line;
    }

    # add optional sections
    my $nsections = 0;
    my %sections-to-add;
    for %sections.kv -> $section, Bool $included {
        next unless %opt-sections{$section}:exists and not $included
        ++$nsections;
        note "DEBUG: section '$section' not found, adding it" if $!debug;
        %sections-to-add{$section} = True;
    }

    # add missing sections in order
    # if so, add a blank line for neatness
    @odistfil.push("") if %sections-to-add.elems;

    for @opt-sections -> $section {
        next unless %sections-to-add{$section}:exists;
        my $str = get-section $section;
        @odistfil.push: $str;
    }

    note "DEBUG: Found $nsections sections" if $!debug;
    $fh = open $distfil, :w;
    $fh.say($_) for @odistfil;
    $fh.close;

    # mod the META6.json file
    if $!descrip {
        my $jfil = "$modpdir/META6.json";
        my %j = App::Mi6::JSON.decode(slurp $jfil);
        my $desc = %j<description>;
        note "DEBUG description: '$!descrip'" if $!debug;
        %j<description> = $!descrip;
        my $jstr = App::Mi6::JSON.encode(%j);
        spurt $jfil, $jstr;
    }

    if $!debug {
        note "DEBUG early exit";
        exit;
    }

    if 0 and $!debug {
        # works okay for Foo::Bar (creates dir Foo-Bar)
        note "Exiting after mi6 create";
        exit
    }

    if is-git-repo $modpdir {
        # need to change dirs
        my $d = $modpdir.IO.absolute;
        #note "'$d' IS a git repo" if 1; #$debug;
        #temp $*CWD = $modpdir.IO;
        #autodie(:on);
        chdir $modpdir;

        cmd("git add .github/workflows/linux.yml");
        cmd("git add .github/workflows/macos.yml");
        cmd("git add .github/workflows/windows.yml");
        cmd("git rm -f .github/workflows/test.yml");
        cmd("git add docs/README.rakudoc");

        # finish the repo to be ready for pushing
        cmd("mi6 build");

        cmd("git add META6.json");
        cmd("git add README.md");
        cmd("git add dist.ini");
        cmd("git add lib/*");

        cmd("git add t/*");
        cmd("git add docs/*");

        #note cmd('git commit -m"initial commit" ').err; # this fails
        run("git", "commit", "-a", "-m'initial'");
    }
    else {
        die "FATAL: Directory '$modpdir' is NOT a git repo!";
    }

} # method !build-mi6-helper

# Note: 'mi6' will abort if the $module-name or $module-dir
#  (as needed) exists. Do NOT check for contents with
#  'mi6-helper'! However, a hidden file is okay (if used).
sub mi6-help() is export {
    # usage
    print qq:to/HERE/;
    Usage: {$*PROGRAM.basename} <mode> [options...]

    Modes:
      new=X - Creates a new module (named 'X') in directory 'P' (default '.')
              by executing 'mi6', then modifying files and adding new files
              in the new repository to add the benefits produced by this module.
              NOTE: The program will abort if directory 'X' exists.

    Options:
      dir=P - Selects directory 'P' as the parent directory for the operations
              (default is '.', the current directory, i.e., '\$*CWD').

      force - Allows the program to continue without a hidden file
              and bypass the promp/response dialog.
    HERE
    exit;
} # sub mi6-help()

sub run-args(@args) is export {
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

    # assume we are in the current working directory
    my $parent-dir = $*CWD; # default

    my $module-name; # Foo::Bar-Baz
    my $module-dir;  # Foo-Bar-Baz

    for @args {
        when /^ :i 'new=' (\S+) / {
            $module-name = ~$0;
            ++$new;
        }
        when /^ :i f / {
            ++$force;
        }
        when /^ 'dir=' (\S+) / {
            $parent-dir = ~$0;
        }
        when /^ :i do  / {
            ++$docs;
        }
        when /^ :i de / {
            ++$debug;
        }
        when /^ :i d2 / {
            # debug 2
            ++$d2;
        }
        when /^ :i d3 / {
            # debug 3
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
        }
        when /^ v / {
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
        die "FATAL: no 'new=X' entered.";
    }

    # Take care of 'descrip'
    unless $descrip.defined {
        $descrip = "";
        # info should be in a hidden file
        my $hidden = ".$module-name";
        $hidden ~~ s:g/'::'/-/;
        my $hfil = "$parent-dir/$hidden";
        if $hfil.IO.r {
            my $s = slurp $hfil.IO;
            for $s.lines {
                $descrip ~= " $_";
            }
            $descrip = normalize-string $descrip;
            say "Getting description text from hidden file '$hidden'";
        }
        elsif not $force {
            print qq:to/HERE/;
            WARNING: Unable to find the hidden file '$hidden'.

            If you want to execute this program without it, you must
            run it with the 'force' option.

            Exiting early.
            HERE
            exit;
        }
    }

    if $parent-dir.defined {
        unless $parent-dir.IO.d {
            die "FATAL: Path '$parent-dir' is not a directory."
        }
    }
    say "Using directory '$parent-dir'\n  as the working directory.";

    # don't need to refer to 'new' again, no block needed for it
    # take care of the module directory: replace '::' with '-'
    $module-dir = $module-name;
    $module-dir ~~ s:g/'::'/-/;

    my $o = Mi6::Helper.new: :$parent-dir, :$module-dir, :$module-name,
                    :$debug, :$force;

    say qq:to/HERE/;
    Exit after 'new' mode run. See new module repo '$module-dir'
    in parent dir '$parent-dir'.
    HERE
    exit;

} # sub run-args
