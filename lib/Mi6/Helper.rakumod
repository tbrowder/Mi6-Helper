unit class Mi6::Helper;

use App::Mi6;
use JSON::Fast;
use Proc::Easier;
use File::Find;

has $.parent-dir = '.';
has $.module-name;             #= as known to Zef, e.g., 'Foo::Bar::Baz'
has $.module-base;             #= as known to git, e.g., 'Foo-Bar-Baz'
# libs are determined by the '::' separators in the module name
has @.libdirs is rw;           #= 'lib/Foo/Bar/Baz.rakumod' 
                               #= 'lib
                               #= 'lib/Foo
                               #= 'lib/Foo/Bar
has $.libfile is rw;           #= 'lib/Foo/Bar/Baz.rakumod;

=begin comment
e.g., Foo-Baz::Bar
=end comment

has $.provides is rw;          #= text to replace 'blah blah blah'
has $.mode is rw;              #= "old" or "new"

submethod TWEAK {
    return if not $!module-name.defined;
    $!module-base = $!module-name;
    $!module-base ~~ s:g/'::'/-/;
}

method mi6-new-cmd(:$parent-dir!, :$module-name!, :$debug, :$debug2) {
    chdir $parent-dir;
    cmd "mi6 new --zef $module-name";
    self.libdirs = find :dir(self.module-base), :type<dir>;
    my $dir = "$!module-base/lib";
    self.libfile = find :$dir, :type<file>;
}

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

method mod-changes() {
}

method mod-readme() {
}

method mod-dist-ini() {
}

sub get-hidden-name(:$module-name) is export {
    my $s = $module-name;
    $s ~~ s:g/'::'/-/;
    $s ~ '.' ~ $s;
}

sub mi6-helper-old(:$parent-dir!, :$module-name!, :$provides, :$debug, :$debug2) is export {
}

sub get-file-content($fnam --> Str) is export {
    %?RESOURCES{$fnam}.slurp;
}

sub mi6-helper-new(:$parent-dir!, :$module-name!, :$provides, :$debug, :$debug2) is export {

    # test module is "Foo::Bar"
    # method mi6-cmd(:$parent-dir, :$module-name) {
    my $o = Mi6::Helper.new: :$module-name;
    $o.mi6-new-cmd(:$parent-dir, :$module-name, :$debug, :$debug2);

    # get the name of the module file to change and move content
    my $modpdir = $module-name;
    my $modpath = $module-name;
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
            if $provides {
                # bold module name and add new text
                $line = "B<$module-name> - $provides"
            }
            else {
                # bold module name only
                $line = "B<$module-name> - "
                #$line ~~ s/\h*$module-name/B<$module-name>/;
            }
        }
        elsif $line.contains("$module-name is") {
            # bold module name
            $line ~~ s/$module-name/B<$module-name>/;
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
        note "DEBUG: section '$section' not found, adding it" if $debug;
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

    note "DEBUG: Found $nsections sections" if $debug;
    $fh = open $distfil, :w;
    $fh.say($_) for @odistfil;
    $fh.close;

    # mod the META6.json file
    if $provides {
        my $jfil = "$modpdir/META6.json";
        my %j = App::Mi6::JSON.decode(slurp $jfil);
        my $desc = %j<description>;
        note "DEBUG description: '$desc'" if $debug;
        %j<description> = $provides;
        my $jstr = App::Mi6::JSON.encode(%j);
        spurt $jfil, $jstr;
    }

    if $debug {
        note "DEBUG early exit";
        exit;
    }

    if 0 and $debug {
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
        note cmd("git add .github/workflows/linux.yml").err;
        note cmd("git add .github/workflows/macos.yml").err;
        note cmd("git add .github/workflows/windows.yml").err;
        note cmd("git rm -f .github/workflows/test.yml").err;
        note cmd("git add docs/README.rakudoc").err;

        # finish the repo to be ready for pushing
        note cmd("mi6 build").err;

        note cmd("git add META6.json").err;
        note cmd("git add README.md").err;
        note cmd("git add dist.ini").err;
        note cmd("git add lib/*").err;

        note cmd("git add t/*").err;
        note cmd("git add docs/*").err;

        #note cmd('git commit -m"initial commit" ').err;
        run("git", "commit", "-a", "-m'initial'");
    }
    else {
        die "FATAL: Directory '$modpdir' is NOT a git repo!";
    }

} # sub mi6-helper-new

sub is-git-repo($dir) {
    "$dir/.git".IO.d;
}

sub get-section($section --> Str) {
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

sub get-version is export {
    $?DISTRIBUTION.meta<version>
}
