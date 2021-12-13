use App::Mi6;

unit class Mi6::Helper;

has $.dir; # the module's top-level directory

# Checks for (1) the library is 
# under Git version control
# and (2) all files are either
# committed or listed in the
# .gitignore file (via use of App:;Mi6).
sub check-git() is export {
}

