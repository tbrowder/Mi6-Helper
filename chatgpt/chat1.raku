#!/usr/bin/env raku

use v6;

# Usage message
sub usage {
    say "Usage: supervisor.raku <script-path> [timeout-in-seconds]";
    exit 1;
}

# Get command-line arguments
my $script = @*ARGS[0] // usage();
my $timeout = (@*ARGS[1] // 5).Int;

unless $script.IO.e {
    say "Error: Script file '$script' not found.";
    exit 1;
}

say "Running script: $script";
say "Timeout set to $timeout second{'s' if $timeout != 1}.";

# Create the process
my $proc = Proc::Async.new('raku', $script);

my $stdout = '';
my $stderr = '';

$proc.stdout.tap(-> $line { $stdout ~= $line ~ "\n" });
$proc.stderr.tap(-> $line { $stderr ~= $line ~ "\n" });

# Start the process
my $promise = $proc.start;

# Create a timeout promise
my $timeout-promise = Promise.in($timeout).then({
    say "Timeout of $timeout seconds reached. Killing process...";
    $proc.kill(SIGKILL);
});

# Wait for either process completion or timeout
await Promise.anyof($promise, $timeout-promise);

# Report results
if $promise.status ~~ Kept {
    say "Process completed successfully.";
    say "Output:\n$stdout" if $stdout.chars;
    say "Errors:\n$stderr" if $stderr.chars;
} else {
    say "Process was killed due to timeout.";
}

# Exit code
exit $promise.status ~~ Kept ?? 0 !! 1;
