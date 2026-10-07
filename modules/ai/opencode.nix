# modules/ai/opencode.nix
#
# opencode agent harness config, per host. The binary itself rides on
# modules.ai.enable (llm-agents' opencode2); this module deploys
# $XDG_CONFIG_HOME/opencode from config/opencode (from Bekaboo/dot's
# .config/opencode, paths adapted to Magi): AGENTS.md, skills, and the
# md-lint plugin. Model choice stays per host via `settings`.
{
  self,
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with self.lib; let
  cfg = config.modules.ai.opencode;
  settingsFormat = pkgs.formats.json {};

  llmAgents = self.inputs.llm-agents.packages;
in {
  options.modules.ai.opencode = with types; {
    enable = mkBoolOpt false;

    settings = mkOpt' settingsFormat.type {} ''
      opencode.json content for this host, merged over `{ autoupdate = false; }`.
      Upstream pins deepseek models; set `settings.model` /
      `settings.small_model` per host instead -- there is no shared
      default model.
    '';
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      llmAgents.opencode2
      markdownlint-cli2
    ];

    environment.shellAliases = {
      oc = "opencode2";
    };

    home.configLink = {
      "opencode/AGENTS.md" = "${config.hey.configDir}/opencode/AGENTS.md";
      "opencode/skills" = "${config.hey.configDir}/opencode/skills";
      "opencode/plugins" = "${config.hey.configDir}/opencode/plugins";
    };

    home.configFile."opencode/opencode.json".source = settingsFormat.generate "opencode.json" (
      {autoupdate = false;} // cfg.settings
    );

    # md-lint.ts reads $HOME/.markdownlint-cli2.cjs. Snapshotted from the flake
    # (like claude.nix), since home.file sources go through builtins.path and
    # a live /etc/magi path is forbidden in pure evaluation.
    home.file.".markdownlint-cli2.cjs".source = "${self.configDir}/opencode/markdownlint-cli2.cjs";
  };
}
