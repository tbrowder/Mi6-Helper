use Test;
eval-dies-ok {
    my $p = run "./bad-prog.raku";
}

done-testing;
