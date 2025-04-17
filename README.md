[![Actions Status](https://github.com/tbrowder/Mi6-Helper/actions/workflows/linux.yml/badge.svg)](https://github.com/tbrowder/Mi6-Helper/actions) [![Actions Status](https://github.com/tbrowder/Mi6-Helper/actions/workflows/macos.yml/badge.svg)](https://github.com/tbrowder/Mi6-Helper/actions) [![Actions Status](https://github.com/tbrowder/Mi6-Helper/actions/workflows/windows.yml/badge.svg)](https://github.com/tbrowder/Mi6-Helper/actions)

NAME
====

**Mi6::Helper** - Creates a base repository for a new Raku module managed by **App::Mi6**

SYNOPSIS
========

This module installs a Raku executable named `mi6-helper` which is designed for the following operation:

    $ mi6-helper new=Foo::Bar

That creates a new module named `Foo::Bar` in the current directory (or a specified directory if the option `dir=/path` is used). The new module is then ready to be enhanced and managed by app `mi6` to easily build build documentation, run tests, and release new versions.

Run `mi6-helper` without arguments to see its help screen showing its options:

        Usage: mi6-helper <mode> [options...]

        Modes:
          new=X - Creates a new module (named 'X') in directory 'P' (default '.')
                  by executing 'mi6', then modifying files and adding new files
                  in the new repository to add the benefits produced by this module.
                  NOTE: The program will abort if directory 'X' exists and has any
                  content.

        Options:
          dir=P - Selects directory 'P' as the parent directory for the operations
                  (default is '.', the current directory, i.e., '\$*CWD').

          force - Allows the program to continue without a hidden file
                  and bypass the promp/response dialog.

DESCRIPTION
===========

The installed program, `mi6-helper`, enables easy creation of a template for a new Raku module repository for management by `App::Mi6`. It does that by first executing `mi6` to create the base module and then modifying the result to add new capabilities. (Note the directory for module 'X::Y-Z' will be 'P/X-Y-Z'. See details in the README.)

Note when `mi6` creates its files, it shows text in the `README.md` file as 'Foo::Bar - blah blah blah'. That can be changed to a brief summary statement by creating a hidden file in the parent directory with the same name as the new diretory. For example, new module `Foo::Bar` will be created in a new directory `Foo-Bar`. You can create hidden file `.Foo-Bar` and put any text desired in it. The author typically puts in text something like this:

    Provides routines to check existing module base repositories for errors.

If the hidden file does not exist, the user will be asked if he or she wishes to continue without it. If the answer is `yes`, then the program will continue and the "blah blah blah" will remain. If the answer is `no`, the program will terminate. (Note the program will wait indefinitely for a response, so you should use option "force" if you are testing or otherwise executing the program apart from a terminal inteface.)

Post repository creation
------------------------

The changes and additions in your new repository include:

1. Modifying the `dist.ini` file for the enhancements

2. User choice of the brief descriptive text (recommended, but not required)

3. `README.md` file source placed in a new `docs/README.rakudoc` file

4. Using three separate OS tests in `.github/workflows`: shows results of each in the now auto-generated `README.md` file

5. Publishing in the **Zef** Raku module ecosystem (now standard with the current `mi6`)

**NOTE**: If one of the non-Linux OS tests fail during remote testing on Github, you can eliminate that test by doing the following two steps (for example, remove the `windows` test which is the most likely to fail):

  * Move the `windows.yml` file out of the `.github/workflows/` directory (the author uses a subdir named `dev` to hold such things).

  * Put a semicolon in the `dist.ini` file to comment out the line naming the `windows.yml` file.

Modified files for the repository
---------------------------------

In addition to those changes, the README is converted to a Rakudoc file in a new `./docs/` directory. Then the `dist.ini` file is modified to create the `README.md` file in the base directory. Both files are placed under `git` control.

See [RepoChanges](zNewMode.md) for full details of each changed line from the original created by `App::Mi6`.

See published module `Foo::Bar` for an example of a module created by `mi6-helper`.

Special installation requirements
---------------------------------

The user must install and have an account with `fez` to use this module to create a new module repository. To do that:

    zef install fez
    fez register

Define the branch `git origin`
------------------------------

The author uses and recommends **GitHub** for the `git origin` for your new module's repository.

A short list of steps to define such for our example 'Foo::Bar':

1. Define a new repo on GitHub named 'Foo-Bar' (note no '::' separator)

2. On your computer, use the shell terminal to run these commands (for Linux or MacOS):

    $ cd /path/to/some-parent-dir
    $ mi6-helper new=Foo::Bar  # <== note the '::' separator, but no quotes

The new repository should be created with a branch name per your personal settings for the Git default branch name (I use 'main' here). This is the output:

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

    # GitHub shows this choice: ...or push an existing repository from the command line...
    # We follow those instructions with our fresh 'Foo::Bar' repo:
    $ git remote add origin git@github.com:user/Foo-Bar.git
    $ git branch -M main
    $ git push -u origin main

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

