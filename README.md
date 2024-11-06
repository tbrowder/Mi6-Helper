[![Actions Status](https://github.com/tbrowder/Mi6-Helper/actions/workflows/linux.yml/badge.svg)](https://github.com/tbrowder/Mi6-Helper/actions) [![Actions Status](https://github.com/tbrowder/Mi6-Helper/actions/workflows/macos.yml/badge.svg)](https://github.com/tbrowder/Mi6-Helper/actions) [![Actions Status](https://github.com/tbrowder/Mi6-Helper/actions/workflows/windows.yml/badge.svg)](https://github.com/tbrowder/Mi6-Helper/actions)

NAME
====

**Mi6::Helper** - An aid for converting Raku modules to use **App::Mi6** and checking Raku module repos for errors

SYNOPSIS
========

NOTE: The next version will remove all 'provides' methods except the use of the hidden file.

    use Mi6::Helper
    $ mi6-helper new=Foo::Bar  # Uses the 'provides' text in hidden file 
                               # '.Foo-Bar'
        or

    $ mi6-helper lint <dir>    # Checks a module directory for errors
                               # and best practice recommendations

**Easily** create the template for a new Raku module repository for management by `App::Mi6` with modifications including:

  * Publishing in the **Zef** Raku module ecosystem

  * User choice of the 'provides' text

  * `README.md` file source removed from the base module and placed in a new `docs/README.rakudoc` file

  * Using three separate OS tests in `.github/workflows` and shows results of each in the `README.md` file

  * A special /sbin/update-meta script to be used by `mi6` as a run-before-build process to ensure the META6.json's 'resources' list matches the files in the </resources> directory

  * Routines to enable showing and downloading files in the /resources directory

  * A new `lint` mode to check existing module repos for possible issues including ensuring the META6.json file reflects the file names in the /resources directory

See published module `Foo::Bar` for an example of a module created by `mi6-helper`.

Special installation requirements
---------------------------------

The user must install and have an account with `fez` to use this module to create a new module repository:

    zef install fez
    fez register

DESCRIPTION
===========

Note this module has changed significantly since the author has had much more experience using **App::Mi6**. For example, discovering that accidentally using `mi6 test` in a non-mi6 module's base directory will corrupt an existing README.md file! (See 'App::Mi6' issue \#157.)

**CAUTION**: Before using this tool on a real module repository, the user should ensure all contents have been comitted with Git to enable recovery from any unwanted changes.

This module installs a Raku executable named `mi6-helper` which is designed for the following modes of operation:

lint
----

  * lint \<path\>

    Checks the module repo in directory \<path\> that the contents of the "resources" list in the 'META6.json' file and the distibution's './resources' directory agree. Modifies them as necessary, displays the proposed changes, and prompts the user for permission to make the changes.

    Also checks for other configuration improvement possibilities. Note the 'lint' mode will work in repos *not* under App::Mi6 management.

    Leaves a report of actions taken and suggestions for improvement in the same directory. The report is named 'mi6-helper-lint.txt'.

    The items checked in this version include:

        * Discrepancies in the META6.json file

        * Obsolete file name conventions: .t, .pl, .pm, .p6, .pl6, .pm6, .pod, .pod6

        * Use of 'perl6' instead of 'raku' in script 'shebang' lines 

        * Use of CI testing using 'zef' instead of 'prove6'

        * Use of Github for version archiving

new
---

  * new=X dir=Y

    Creates a new module 'X' in parent directory 'Y' (default '.') using **mi6** and then changes some of the files and directories to satisfy the 'docs' option and, optionally, substitute 'blah...' with the user's short description (if it is provided).

    Provides a final `mi6 build` and `git commit -a -m"initial commit"` so the new repository is ready to `git push <remote> <branch>` and `mi6 release`.

    CAUTION: If file `dist.ini` already exists in the parent directory, the program will abort **unless** the `force` option is used. Use the `force` option at your own risk!

**NOTE**: If one of the non-Linux OS tests fail, you can eliminate that test by doing the following two steps (for example, remove the `macos` test):

  * Move the `macos.yml` file out of the `.github/workflows/` directory (the author uses a subdir named `dev` to hold such things).

  * Put a semicolon in the `dist.ini` file to comment out the line naming the `macos.yml` file

Modified files for mode **new**
-------------------------------

See [NewMode](NewMode.md) for details of each changed line.

### Files with replaced, modified, or added lines:

      dist.ini:
        # The line that reads:
        filename = lib/Foo/Bar.rakumod
        # is changed to:
        filename = docs/README.rakudoc
        # the following App::Mi6 optional sections are added
        # if not found:
        #   PruneFiles
        #   MetaNoIndex
        #   AutoScanPackages
        #   RunBeforeBuild
        #   RunAfterBuild


      META6.json:
        # The line that begins:
        "description": "blah blah blah",
        # is changed to:
        "description": "[text entered per the 'provides=X' option]

      lib/Foo/Bar.rakumod:
        # Move all lines following the first non-blank line
        # thus leaving:
        unit class Foo::Bar;

      .github/workflows/test.yml:
        # Create three new files to provide three separate test badges
        .github/workflows/linux.yml
        .github/workflows/windows.yml
        .github/workflows/macos.yml
        # Remove the original test.yml file

### New directory and file:

      # new directory
      docs/
        # new file:
        README.rakudoc
        # This new file first gets all the lines removed from
        # 'lib/Foo/Bar.rakumod' resulting in a complete pod
        # document:
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

AUTHOR
======

Tom Browder <tbrowder@acm.org>

CREDITS
=======

The very useful Raku modules used herein:

  * `App::Mi6` by **zef:skaji**

  * `File::Directory::Tree` by **github:labster**

  * `File::Temp` by **zef:rbt**

  * `Proc::Easier` by **zef:sdondley**

  * `File::Find` by **zef:raku-community-modules**

  * `MacOS::NativeLib` by **zef:lizmat**

COPYRIGHT AND LICENSE
=====================

&#x00A9; 2020-2024 Tom Browder

This library is free software; you may redistribute it or modify it under the Artistic License 2.0.

