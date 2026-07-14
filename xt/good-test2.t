use Test;
dies-ok {
    sink my $p = run("./bad-prog.raku");
}

done-testing;
