[![Actions Status](https://github.com/tbrowder/Mi6-Helper/workflows/test/badge.svg)](https://github.com/tbrowder/Mi6-Helper/actions)

NAME
====

**Mi6::Helper** - An aid for converting Raku modules to use **App::Mi6**

SYNOPSIS
========

    use Mi6::Helper

    $ mi6-helper new=Foo::Bar provides=Bar-description.txt

DESCRIPTION
===========

Note this is API 2 and its approach has changed significantly since the author has had much more experience using **App::Mi6**. For example, accidentally using `mi6 test` in a non-mi6 module's base directory will corrupt an existing README.md file!

**CAUTION**: Before using this tool on a real module repository, the user should ensure all contents have been comitted with Git to enable recovery from any unwanted changes.

This module installs a Raku executable named `mi6-helper` which is designed for two major modes of operation:

  * new=X dir=Y

    Creates a new module 'X' in parent directory 'Y' (default '.') using **mi6** and then changes some of the files and directories to satisfy the 'docs' option and, optionally, substitute 'blah...' with the user's short description (if it is provided).

    CAUTION: If file `dist.ini` already exists in the parent directory, the program will abort **unless** the `force` option is used. Use the `force` option at your own risk!

  * old ***NOT YET IMPLEMENTED***

    Inspects an existing Git repository of a Raku module to help convert it to one that uses the `App::Mi6` module with the Zef repository. Essentially all it does is add or mofify the following files:

      * Changes

      * dist.ini

      * README.md

Modified files for mode **new**
-------------------------------

### Files with replaced, modified, or added lines:

      dist.ini:
        # The line that reads:
        filename = lib/Foo/Bar.rakumod
        # is changed to:
        filename = docs/README.rakudoc

      META6.json:
        # The line that begins:
        "description": "blah blah blah",
        # is changed to:
        "description": "[text entered per the 'provides=X' option]

      lib/Foo/Bar.rakumod:
        # Move all lines following the first non-blank line
        # thus leaving:
        unit class Foo::Bar;

### New directory and file:

      # new directory
      docs/
        # new file:
        README.rakudoc
        # This new file first gets all the lines removed from
        # 'lib/Foo/Bar.rakumod' resulting in a complete pod
        # documement:
        =begin pod
           ...
        =end pod
        # Then, four lines are changed:

        # 1. The line that begins:
        Foo::Bar - blah blah blah
        # is changed to either:
        B<Foo::Bar> - [Foo::Bar is bolded, text entered per the 'provides=X' option]
        # or:
        B<Foo::Bar> - blah blah blah [Foo::Bar is bolded]

        # 2. The line that begins:
        Foo::Bar is ...
        # is changed to:
        B<Foo::Bar> is ...

        # 3. The line that begins:
        Copyright {current year} ...
        # is changed to:
        <copyright symbol> {current year} ...

        # 4. The line that reads:
        This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
        # is changed to better English::
        This library is free software; you may redistribute it or modify it under the Artistic License 2.0.

AUTHOR
======

Tom Browder <tbrowder@acm.org>

CREDITS
=======

The very useful Raku modules used herein:

  * `App::Mi6` by **github:skaji**

  * `File::Find` by **github:tadzik**

COPYRIGHT AND LICENSE
=====================

&#x00A9; 2020-2022 Tom Browder

This library is free software; you may redistribute it or modify it under the Artistic License 2.0.

