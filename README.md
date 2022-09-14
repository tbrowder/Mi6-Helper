[![Actions Status](https://github.com/tbrowder/Mi6-Helper/workflows/test/badge.svg)](https://github.com/tbrowder/Mi6-Helper/actions)

NAME
====

**Mi6::Helper** - An aid for converting Raku modules to use **App::Mi6**

SYNOPSIS
========

Note this is API 2 and its approach has changed significantly since the author has had much more experience using **App::Mi6**. For example, accidentally using `mi6 test` in a non-mi6 module's base directory will corrupt an existing README.md file.

**CAUTION**: Before using this tool on a real module repository, the user should ensure all contents have been comitted with Git to enable recovery from any unwanted changes.

This module installs a Raku executable named `mi6-helper` which is designed for two major modes of operation: 

  * old

    Inspect an existing Git repository of a Raku module to help convert it to one that uses the `App::Mi6` module with the Zef repository. Essentially all it does is add or mofify the following files:

      * Changes

      * dist.ini

      * README.md

    See more details below.

  * new

    Create a new module using **mi6** and then change some of the contents to satisfy the 'docs' option and, optionally, substitute 'blah...' with the user's short description.

Modified files
--------------

  * **dist.ini** (in the base directory)

    This file, if found existing, will cause an abort. No changes can be made to an existing file. You may use the `force` option at your own risk.

    The default file does **NOT** create any Markdown files from any source unless you are the user **tbrowder** or you use the `docs` option. In those cases a **docs/README.rakudoc** file is created and this file is modified appropriately.

  * **README.md** (in the base directory)

    This file, if it exists, is copied to a file named **README.md.original** for safety. The original file is not modified by this program.

  * **Changes** (in the base directory)

    If a **Changes** file happens to exist, it will be copied to a **Changes.original** file and the original will be overwritten with one in the correct format.

  * **docs/README.rakudoc** (in the base/docs directory)

    If such a file exists, it will be left unchanged.

The default changes to the `dist.ini` file those the author likes, but a future update will allow the user to customize those actions in his or her own `$HOME/.mi6helper-ini` file.

The contents of the two files are shown below.

**Changes** file
----------------

**dist.ini** file (benign version for non-mi6 repositories)
-----------------------------------------------------------

**dist.ini** file (version for newly created mi6 repositories)
--------------------------------------------------------------

DESCRIPTION
===========

    sub get-mod-name
      - determine the base module name
        - check any dist.ini file
        - check the META6.json file
        - throw if not found or there are conflicts

AUTHOR
======

Tom Browder <tbrowder@acm.org>

CREDITS
=======

The very useful Raku modules used herein:

  * `App::Mi6` by **github:skaji**

  * `File::Find` by **github:tadzik**

  * `JSON::Fast` by **github:timo**

  * `Config::INI` by **gitbub:tadzik**

COPYRIGHT AND LICENSE
=====================

Copyright &#x00A9; 2020-2022 Tom Browder

This library is free software; you may redistribute it or modify it under the Artistic License 2.0.

