[![Actions Status](https://github.com/tbrowder/Mi6-Helper/workflows/test/badge.svg)](https://github.com/tbrowder/Mi6-Helper/actions)

NAME
====

**Mi6::Helper** - An aid for converting Raku modules to use **App::Mi6**

SYNOPSIS
========

Note this is API 2 and its approach has changed significantly since the author has had much more experience using **App::Mi6**. For example, accidentally using `mi6 test` in a non-mi6 module's base directory will corrupt an existing README.md file.

This module installs a Raku executable named `mi6-helper` which is designed to inspect an existing Git repository of a Raku module to help convert it to one that uses the `App::Mi6` module with the Zef repository. Essentially all it does is add a `dist.ini` file and a `Changes` file to the base directory. If a `Changes` file happens to exist, it will be copied to a `` file and the original will be overwritten with one in the correct format.

The default actions are those the author likes, but a future update will allow the user to customize those actions in his or her own `$HOME/.mi6helper` file.

The contents of the two files are shown below.

**Changes** file
----------------

**dist.ini** file
-----------------

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

