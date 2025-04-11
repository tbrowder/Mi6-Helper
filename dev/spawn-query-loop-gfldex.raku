#!/usr/bin/env raku

# @gfldex

use Proc::Async::Timeout;

my $s = Proc::Async.new(
    run "sbin/get-response", "file=some-file"
);
$s.stdout.lines.tap: { .say if .lc.contains(any <some-file>) }
$s.stderr.tap: { Nil }

await $s.start: timeout => 2;

CATCH {
    when X::Proc::Async::Timeout {
        say "caught: ", .^name;
        say "reporting: ", .Str;
    }
    when X::Promise::Broken ^ X::Proc::Async::Timeout {
        say "something else went wrong";
    }
}

# OUTPUT:
# cought: X::Proc::Async::Timeout+{X::Promise::Broken}
# reporting: ⟨sleep⟩ timed out after 2 seconds.
