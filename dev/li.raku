#!/usr/bin/env raku

my $line = q:to/HERE/;

line-1 blan ndjfj

  djjfn

HERE

$line = $line.lines.words.join(" ");
say $line;

$line = q:to/HERE/.lines.words.join(" ");

line-2 blan ndjfj

  djjfn

HERE
say $line;




