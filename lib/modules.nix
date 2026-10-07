{ lib }:

let
  inherit (builtins) attrValues readDir pathExists;
  inherit (lib) attrNames concatMap concatMapAttrs filter hasPrefix hasSuffix id
                removeSuffix;

  # The rule every walker shares for a plain file: only .nix files count, minus
  # default.nix (a directory's own entry point, taken as the directory) and
  # flake.nix (never a module).
  isModuleFile = n: v:
    v == "regular"
    && n != "default.nix"
    && n != "flake.nix"
    && hasSuffix ".nix" n;

  # Walks DIR one level deep and returns { <name> = ...; }, dropping the ".nix"
  # suffix from file names. Module files are mapped through FN; directories are
  # mapped through ONDIR. Skip files/dirs prefixed with '_'.
  walk = onDir: dir: fn:
    let dir' = toString dir; in
    concatMapAttrs
      (n: v:
        let path = "${dir'}/${n}"; in
        if hasPrefix "_" n then {}
        else if v == "directory" then onDir n path fn
        else if isModuleFile n v then { ${removeSuffix ".nix" n} = fn path; }
        else {})
      (readDir dir');
in rec {
  # dir -> fn :: attrs
  #
  # Maps every module directly under DIR through FN. A directory counts as a
  # module only if it holds a default.nix, in which case FN gets the directory.
  mapModules =
    walk (n: path: fn:
      if pathExists "${path}/default.nix"
      then { ${n} = fn path; }
      else {});

  # dir -> fn :: listOf any
  #
  # mapModules, as a list of its values.
  mapModules' = dir: fn:
    attrValues (mapModules dir fn);

  # dir -> fn :: attrs (attrs (attrs ...))
  #
  # Creates a file tree where each leaf is the result of FN. Like mapModules,
  # but recursively descends into DIR.
  mapModulesRec =
    walk (n: path: fn: { ${n} = mapModulesRec path fn; });

  # dir :: listOf string
  #
  # Every module path under DIR, recursively: at each level, the files
  # mapModules would take, plus any directory holding a default.nix (as the
  # directory, which import resolves to that file).
  modulePaths = dir:
    let
      dir' = toString dir;
      entries = readDir dir';
      subdirs =
        filter
          (n: entries.${n} == "directory" && !(hasPrefix "_" n))
          (attrNames entries);
    in
      attrValues (mapModules dir' id)
      ++ concatMap (n: modulePaths "${dir'}/${n}") subdirs;

  # dir -> fn :: listOf any
  #
  # Returns a list of all module paths under DIR, mapped by FN.
  mapModulesRec' = dir: fn:
    map fn (modulePaths dir);

  # dir :: attrs
  #
  # Every host under DIR as { <name> = { path, config }; }, where config is the
  # host's unapplied module function. mkFlake applies it (see lib/nixos.nix), so
  # a host can be inspected without being evaluated into a NixOS system.
  mapHosts = dir:
    mapModules dir (path: {
      inherit path;
      config = import path;
    });
}
