use Test;

dies-ok {
    my $p = run "-I", "./bad-prog.raku";
}
