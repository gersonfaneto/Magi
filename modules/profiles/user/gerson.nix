# modules/profiles/user/gerson.nix

{ lib, config, pkgs, ... }:

with lib;
let cfg = config.modules.profiles;
    username = cfg.user;
    role = cfg.role;
    key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBCR4vGEX3k2Z9pbpRNGqBiHhbT8ZzAsi9DxCmmKHBqO";
in mkIf (username == "gerson") (mkMerge [
  {
    user.name = username;
    user.description = "Gerson Ferreira";
    i18n.defaultLocale = mkDefault "en_US.UTF-8";

    user.openssh.authorizedKeys.keys = [ key ];

    # Allow key-based root access only from private ranges.
    users.users.root.openssh.authorizedKeys.keys = [
      (if role == "workstation"
       then ''from="10.0.0.0/8,172.16.0.0/12,192.168.0.0/16" ${key} ${username}''
       else key)
    ];
  }
])