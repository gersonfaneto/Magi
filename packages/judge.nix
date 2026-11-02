# packages/judge.nix -- the test runner behind `magi test magi`
{callPackage, ...}:
(callPackage ./_janet.nix {}).judge
