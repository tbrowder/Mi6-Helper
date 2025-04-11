# @gfldex

use Test;

use Proc::Async::Timeout;

use Mi6::Helper;

my $timeout = 5;
dies-ok {
    my $s = Proc::Async::Timeout.new(
        run "sbin/get-response", "file=some-file"
    );
    $s.stdout.lines.tap: { .say if .lc.contains(/^ :i /) }
    $s.stderr.tap: { Nil }

    await $s.start: timeout => $timeout;

    =begin comment
    CATCH {
        when X::Proc::Async::Timeout {
            say "caught: ", .^name;
            say "reporting: ", .Str;
            say "killing the process...";
            $s.kill;
        }
        when X::Promise::Broken ^ X::Proc::Async::Timeout {
            say "something else went wrong";
        }
    }
    # OUTPUT:
    # cought: X::Proc::Async::Timeout+{X::Promise::Broken}
    # reporting: ⟨sleep⟩ timed out after 2 seconds.
    =end comment
}, " run without 'force' option for a missing hidden file"
