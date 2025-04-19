Changes to the `mi6` repo
=========================

Modified files
--------------

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
        "description": "[text entered per the text in the hidden file]

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
        B<Foo::Bar> - [Foo::Bar is bolded, text from the hidden file '.Foo-Bar']
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
        # is changed to:
        This library is free software; you may redistribute it or modify it under the Artistic License 2.0.

