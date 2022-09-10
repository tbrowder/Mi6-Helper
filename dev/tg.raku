use LibGit2;

my $repo;

try $repo = Git::Repository.open: "foo";
if not $repo {
    die "FATAL: foo is not a git repo";
}

