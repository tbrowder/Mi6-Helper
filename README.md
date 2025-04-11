[![Actions Status](https://github.com/tbrowder/Mi6-Helper/actions/workflows/linux.yml/badge.svg)](https://github.com/tbrowder/Mi6-Helper/actions) [![Actions Status](https://github.com/tbrowder/Mi6-Helper/actions/workflows/macos.yml/badge.svg)](https://github.com/tbrowder/Mi6-Helper/actions) [![Actions Status](https://github.com/tbrowder/Mi6-Helper/actions/workflows/windows.yml/badge.svg)](https://github.com/tbrowder/Mi6-Helper/actions)

NAME
====

**Mi6::Helper** - Creates a base repository for a new Raku module managed by **App::Mi6**

SYNOPSIS
========

    use Mi6::Helper
    $ mi6-helper new=Foo::Bar  # Uses the brief descriptive text in
                               # hidden file '.Foo-Bar' (if any)

DESCRIPTION
===========

**Easily** create the template for a new Raku module repository for management by `App::Mi6`.

This module creates a new repo by running 'mi6' (from module 'App::Mi6'), and then modifies that output by running this module's 'mi6-helper' to get modifications including:

  * User choice of the brief descriptive text (recommended, but not required)

  * `README.md` file source placed in a new `docs/README.rakudoc` file

  * Using three separate OS tests in `.github/workflows`: shows results of each in the auto-geberated `README.md` file

  * Publishing in the **Zef** Raku module ecosystem (now standard with the current 'mi6')

See published module `Foo::Bar` for an example of a module created by `mi6-helper`.

Special installation requirements
---------------------------------

The user must install and have an account with `fez` to use this module to create a new module repository:

    zef install fez
    fez register

Define the branch 'git origin'
------------------------------

The author uses and recommends GitHub for the 'git origin' for your new module's repository.

A short list of steps to define such for our example 'Foo::Bar':

1. Define a new repo on GitHub named 'Foo-Bar' (note no '::' separator)

2. On your computer, use the shell terminal to run these commands (for Linux or MacOS):

    $ cd /path/to/some-parent-dir
    $ mi6-helper new=Foo::Bar  # <== note the '::' separator, but no quotes

The repo should be created with a branch name per your personal settings for the default branch name (I use 'main' here). This is the output:

    Getting description text from hidden file '.Foo-Bar'
    [main (root-commit) 30a8b25] 'initial'
     12 files changed, 431 insertions(+)
     create mode 100644 .github/workflows/linux.yml
     create mode 100644 .github/workflows/macos.yml
     create mode 100644 .github/workflows/windows.yml
     create mode 100644 .gitignore
     create mode 100644 Changes
     create mode 100644 LICENSE
     create mode 100644 META6.json
     create mode 100644 README.md
     create mode 100644 dist.ini
     create mode 100644 docs/README.rakudoc
     create mode 100644 lib/Foo/Bar.rakumod
     create mode 100644 t/0-load-test.rakutest
    Using directory '/path/to/some-parent-dir'
      as the working directory.
    Exit after 'new' mode run. See new module repo 'Foo-Bar'
    in parent dir '/path/to/some-parent-dir'.

At this point, execute the following commands to define the origin and push the new branch to the repo awaiting it on GitHub:

    # GitHub: ...or push an existing repository from the command line...
    # following those instructions with our fresh Foo::Bar repo:
    $ git remote add origin git@github.com:user/Foo-Bar.git
    $ git branch -M main
    $ git push -u origin main

Note this module has changed significantly since the author has had much more experience using **App::Mi6**. For example, discovering that accidentally using `mi6 test` in a non-mi6 module's base directory will corrupt an existing README.md file! (See 'App::Mi6' issue \#157.)

This module installs a Raku executable named `mi6-helper` which is designed for the following mode of operation:

new
---

  * new=X dir=Y

    Creates a new module 'X' in parent directory 'Y' (default '.') using **mi6** and then changes some of the files and directories to satisfy the 'docs' option and, optionally, substitute 'blah...' with the user's short description (if it is provided in a hidden file).

    Provides a final `mi6 build` and `git commit -a -m"initial commit"` so the new repository is ready to `git push <remote> <branch>` and `mi6 release`.

**NOTE**: If one of the non-Linux OS tests fail, you can eliminate that test by doing the following two steps (for example, remove the `macos` test):

  * Move the `macos.yml` file out of the `.github/workflows/` directory (the author uses a subdir named `dev` to hold such things).

  * Put a semicolon in the `dist.ini` file to comment out the line naming the `macos.yml` file

Modified files for mode **new**
-------------------------------

See [NewMode](zNewMode.md) for details of each changed line from the original created by `App::Mi6`.

In addition to those changes, the README is converted to a Rakudoc file in a new `./docs/` directory. Then the 'dist.ini' file is modified to create the 'README.md' file in the base directory. Both files are placed under 'git' control.

See also
--------

A new, in-work [App::DistroLint](https://github.com/tbrowder/App-DistroLint) by the author.

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

&#x00A9; 2020-2025 Tom Browder

This library is free software; you may redistribute it or modify it under the Artistic License 2.0.

