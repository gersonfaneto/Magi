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
  cfg = config.modules.shell.tmux;
in {
  options.modules.shell.tmux = with types; {
    enable = mkBoolOpt false;
    term = mkOpt str "xterm-256color";
    rcFiles = mkOpt (listOf (either str path)) [];
  };

  config = mkIf cfg.enable {
    environment.variables = {
      TMUX_HOME = "${config.magi.configDir}/tmux";
    };

    # I avoid programs.tmux because it comes with extra magic I don't need.
    user.packages = with pkgs; [
      tmux
    ];

    environment.etc."tmux.conf".text = with pkgs.tmuxPlugins; ''
      set -s default-terminal "${cfg.term}"

      source-file $TMUX_HOME/tmux.conf
      ${concatMapStrings (path: "source-file '${path}'\n") cfg.rcFiles}

      # Run plugins
      run-shell ${continuum.rtp}
      run-shell ${resurrect.rtp}

      run-shell ${extrakto.rtp}
      run-shell ${fuzzback.rtp}
      run-shell ${prefix-highlight.rtp}

      # Rendered by the desktop palette pipeline. Hosts without it skip the
      # file, and the live config above still applies.
      if-shell '[ -r ${config.home.configDir}/tmux/theme.conf ]' 'source-file ${config.home.configDir}/tmux/theme.conf'
    '';

    modules.wm.theme.files.tmux = {
      input_path = "${config.magi.configDir}/theme/tmux.template.conf";
      output_path = "${config.home.configDir}/tmux/theme.conf";
      scope = "terminal";
      # Tmux doesn't reread its config, so update the default server. Multiple
      # servers (or no running server) are left alone.
      post_hook = "tmux source-file ${config.home.configDir}/tmux/theme.conf 2>/dev/null || true";
    };

    modules.shell.zsh.rcFiles = ["${config.magi.configDir}/tmux/aliases.zsh"];
  };
}
