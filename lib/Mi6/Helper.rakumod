unit class Mi6::Helper:ver<0.0.1>:auth<cpan:TBROWDER>;


=begin pod

=head1 NAME

Mi6::Helper - An aid for converting Raku modules to use App::Mi6

=head1 SYNOPSIS

This module installs a Raku executable named C<mi6-helper> which
is designed to inspect an existing Git repository of a Raku
module to help convert it to one that uses the C<App::Mi6> module.

=begin code :lang<raku>
$ mi6-helper <raku-module-repo-name>
=end code

The C<<raku-module-repo-name>> may be a C<.> if you are working in
the repository directory.

=head1 DESCRIPTION

The executable program exists but has no useful operation yet other
than a quick inspection and limited reporting. See the following
section for the design features planned.

=head2 GOAL

What am I trying to accomplish?

=begin code
- Convert an existing module to use App::Mi6

- Process in order

sub check-git
  - ensure there is a .git file
    - throw if not

  - check if needing a commit
    - throw if not

  # From this point, all changes to existing files should
  # protected by Git and new files will listed as untracked.
  # If the user fails to add the files or commit them,
  # mi6 will cath the errors upon build or release.

sub get-mod-name
  - determine the base module name
    - check any dist.ini file
    - check the META6.json file
    - throw if not found or there are conflicts

sub get-mod-type
  - determine whether it's a module or a class (affects the type
    of load test)

sub check-mi6-files
  - check for missing files required by mi6
    - write my version
  - remove the dummy test created by mi6, if any

sub check-my-std-test-files
  - check for and create missing standard
    tests I use
    - Test::Meta
    - load or class test

sub find-external-mods-used
  - determine external modules used by the module being analyzed

sub write-meta6-json
  - rewrite the META6.json file (create a backup copy)
    - ensure depends and test depends are correct

sub write-dist-ini
  - rewrite the dist.ini file (create a backup copy)
    - IMPORTANT ensure the convert to pod is turned OFF until manually changed

  - check for the Unicode Copyright symbol [Copyright  &#x00A9; 2020 <author>] in the source pod
    for the README.md file
    - report results

  - use prompts where need be
=end code

=head1 AUTHOR

Tom Browder <tom.browder@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2020 Tom Browder

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
