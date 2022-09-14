#!/usr/bin/env raku

if not @*ARGS.elems {
    print qq:to/HERE/;

    Usage: {$*PROGRAM.basename} <mode> image [options...]

    This program uses the 'GraphicsMagick' library to crop an image
    to a 100x100 size about a selected point. Dimensions and
    points are given in pixels: X=width, Y=height.

    Modes:
      show      - Shows the image dimensions in pixels along with other
                   details including a copy of the original with a 100-pixel
                   square superimposed upon the center of the picture.
      crop      - Crops the image to 100x100 pixels about the center of
                   the image or the user-defined point.

    Options:
      point=X,Y - Define the desired 100-pixel square center point
      debug     - Developer use

    HERE
    exit;
}

