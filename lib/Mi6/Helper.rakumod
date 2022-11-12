unit class Mi6::Helper;

use App::Mi6;

has $.parent-dir = '.';
has $.module-name;             #= e.g., 'Foo::Bar'
has $.provides;                #= text to replace 'blah blah blah'
has $.mode;                    #= "old" or "new"
has $.module-base;             #= e.g., 'Foo-Bar'

submethod TWEAK {
    return if not $!module-name.defined;
    $!module-base = $!module-name;
    $!module-base ~~ s:g/'::'/-/;
}

method mi6-new-cmd(:$parent-dir, :$module-name, :$debug) {
    chdir $parent-dir;
    run "mi6", 'new', '--zef', $module-name;
}

method git-user-email {
    run("git", "config", "--get", "--global", "user.email", :out).out.slurp.chomp
}

method git-user-name {
    run("git", "config", "--get", "--global", "user.name", :out).out.slurp.chomp
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

sub mi6-helper-new(:$parent-dir, :$module-name, :$provides, :$debug) is export {

    # test module is "Foo::Bar"
    # method mi6-cmd(:$parent-dir, :$module-name) {
    my $o = Mi6::Helper.new: :$module-name;
    $o.mi6-new-cmd(:$parent-dir, :$module-name, :$debug);

    # get the name of the module file to change and move content
    my $modpdir = $module-name;
    my $modpath = $module-name;
    $modpdir ~~ s:g/'::'/-/;
    $modpath ~~ s:g/'::'/\//;
    my $mpath = "$modpdir/lib/$modpath";
    say "DEBUG: Foo::Bar path: '$mpath'" if $debug;

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
        if $line.contains('blah') {
            if $provides {
                # bold module name and add new text
                $line = "B<$module-name> - $provides"
            }
            else {
                # bold module name only
                $line ~~ s/\h*$module-name/B<$module-name>/;
            }
        }
        elsif $line.contains("$module-name is") {
            # bold module name
            $line ~~ s/$module-name/B<$module-name>/;
        }
        elsif $line ~~ /^ \h* Copyright/ {
            # use copyright symbol
            #  Copyright © 2021 Tom Browder
            #  Copyright E<0x00a9> 2021 Tom Browder
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

    # mod the .github/workflows/test.yml files
    my $testfil  = "$modpdir/.github/workflows/test.yml";
    my @itestfil = $testfil.IO.lines;

    my $Lfil = "$modpdir/.github/workflows/linux.yml";
    my $Wfil = "$modpdir/.github/workflows/windows.yml";
    my $Mfil = "$modpdir/.github/workflows/macos.yml";

    my $Lfh = open $Lfil, :w;
    my $Wfh = open $Wfil, :w;
    my $Mfh = open $Mfil, :w;

    while @itestfil.elems {
        my $line = @itestfil.shift;
        if $line ~~ /'name:' \h+ test / {
            $Lfh.say: "name: Linux";
            $Wfh.say: "name: Win64";
            $Mfh.say: "name: MacOS";
            next;
        }
        if $line ~~ /'-' \h+ [ubuntu|windows|macos] '-' latest / {
            # need to replace three lines with one
            @itestfil.shift;
            @itestfil.shift;
            $Lfh.say: "name: Linux";
            $Wfh.say: "name: Win64";
            $Mfh.say: "name: MacOS";
            next;
        }
        $Lfh.say: $line;
        $Wfh.say: $line;
        $Mfh.say: $line;
    }
    $Lfh.close;
    $Wfh.close;
    $Mfh.close;
    unlink $testfil; # don't need the old one

    # mod the dist.ini file
    my $distfil  = "$modpdir/dist.ini";
    my @idistfil = $distfil.IO.lines;
    my @odistfil;
    for @idistfil -> $line is copy {
        # change the README line
        #   filename = lib/Foo/Bar.rakumod
        if $line ~~ /filename \h+ '=' / {
            $line = "filename = docs/README.rakudoc";
            @odistfil.push: $line;
        }
        elsif $line ~~ /provider \h+ '=' / {
            $line = "provider = github-actions/linux.yml";
            @odistfil.push: $line;
            $line = "provider = github-actions/macos.yml";
            @odistfil.push: $line;
            $line = "provider = github-actions/windows.yml";
            @odistfil.push: $line;
        }
    }
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

} # sub mi6-helper-new
