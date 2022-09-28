unit class Mi6::Helper;

use JSON::Fast;

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
        if $provides and $line.contains('blah') {
            # bold module name and add new text
            $line = "B<$module-name> - $provides"
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
        note "DEBUG description: '$desc'" if $debug;
        %j<description> = $provides;
        my $jstr = to-json %j;
        spurt $jfil, $jstr;
    }

    if $debug {
        note "DEBUG early exit";
        exit;
    }

    if $debug {
        # works okay for Foo::Bar (creates dir Foo-Bar)
        note "Exiting after mi6 create";
        exit
    }

} # sub mi6-helper-new
