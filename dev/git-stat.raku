#!/usr/bin/env raku

use Git::Status;

if not @*ARGS.elems {
    print qq:to/HERE/;
    Usage: {$*PROGRAM.basename} <dir>

    Checks the Git status of directory 'dir'

    HERE
    exit;
}

my $directory = @*ARGS.shift;

my $gs = Git::Status.new: :$directory;

say $gs.gist;

