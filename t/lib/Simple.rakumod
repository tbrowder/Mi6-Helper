unit class Simple;

use App::Mi6;

has $.module-name is required; #= as known to Zef, e.g., 'Foo::Bar-Baz'
has $.module-dir;              #= as known to git, e.g., 'Foo-Bar-Baz'
has $.parent-dir; 

submethod TWEAK {
    # determine module-dir
    $!module-dir = $!module-name;
    $!module-dir ~~ s/'::'/-/;

    # determine parent-dir
    if $!parent-dir.defined {
        chdir $!parent-dir;
    }
    else {
        $!parent-dir = $*CWD;
    }
    if $!module-dir.IO ~~ :d {
        die "FATAL: Directory '$!module-dir' already exists";
    }
} # end of TWEAK

