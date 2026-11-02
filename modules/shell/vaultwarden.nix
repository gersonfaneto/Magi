# modules/shell/vaultwarden.nix
{
  self,
  lib,
  config,
  options,
  pkgs,
  ...
}:
with lib;
with self.lib; let
  inherit (self.lib.pkgs) mkLauncherEntry;

  cfg = config.modules.shell.vaultwarden;
  gpgPinentry = config.modules.shell.gnupg.pinentry;
  rbw = getExe pkgs.rbw;
  jq = getExe pkgs.jq;
in {
  options.modules.shell.vaultwarden = with types; {
    enable = mkBoolOpt false;
    settings = mkOpt (attrsOf (either str int)) {};
  };

  config = mkIf cfg.enable {
    user.packages = [
      pkgs.rbw
      (mkLauncherEntry "Bitwarden Entry ->" {
        description = "Search, unlock, and copy via the Quickshell pill";
        icon = "dialog-password";
        exec = "magi @menu rbw";
      })
      (mkLauncherEntry "New Bitwarden Entry ->" {
        description = "Generate and save a login via the Quickshell pill";
        icon = "list-add";
        exec = "magi @menu rbw --new";
      })
    ];

    modules.shell.vaultwarden.settings.pinentry = mkDefault (
      if gpgPinentry != null
      then gpgPinentry
      else getExe pkgs.pinentry-curses
    );

    # `rbw config set` stops the agent (and locks the vault) every time, so
    # only touch what's actually drifted, or every rebuild would lock me out.
    system.userActivationScripts.magi-init-rbw = ''
      current=$(${rbw} config show 2>/dev/null || echo '{}')
      ${concatStrings (
        mapAttrsToList (
          n: v: let
            v' = escapeShellArg (toString v);
          in ''
            if [ "$(echo "$current" | ${jq} -r '.${n} // empty')" != ${v'} ]; then
              ${rbw} config set ${n} ${v'} || echo "rbw: couldn't set ${n}" >&2
            fi
          ''
        )
        cfg.settings
      )}
    '';
  };
}
