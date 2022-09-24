#use App::Mi6;

unit class Mi6::Helper;

has $.dir;
has $.provides;

method mi6-cmd(:$parent-dir, :$new-module, :$debug) {
    run "mi6", 'new', '--zef', $new-module;
}

method mod-changes() {
}

method mod-readme() {
}

method mod-dist-ini() {
}



