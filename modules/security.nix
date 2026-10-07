{ lib, config, ... }:

{
  ## System security tweaks
  # tmpfs = /tmp is mounted in ram. Doing so makes temp file management speedy
  # on ssd systems and more secure (and volatile!) because it's wiped on reboot.
  boot.tmp.useTmpfs = lib.mkDefault true;
  boot.tmp.tmpfsSize = lib.mkDefault "75%";  # in case of big builds
  # If not using tmpfs, which is naturally purged on reboot, we must clean it
  # /tmp ourselves. /tmp should be volatile storage!
  boot.tmp.cleanOnBoot = lib.mkDefault (!config.boot.tmp.useTmpfs);

  # Fix a security hole in place for backwards compatibility. See desc in
  # nixpkgs/nixos/modules/system/boot/loader/systemd-boot/systemd-boot.nix
  boot.loader.systemd-boot.editor = lib.mkDefault false;

  boot.kernel.sysctl = {
    ## TCP hardening
    # Prevent bogus ICMP errors from filling up logs.
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    # Do not accept IP source route packets (we're not a router)
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    # Don't send ICMP redirects (again, we're not a router)
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    # Refuse ICMP redirects (MITM mitigations)
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    # Protects against SYN flood attacks
    "net.ipv4.tcp_syncookies" = 1;
    # Incomplete protection again TIME-WAIT assassination
    "net.ipv4.tcp_rfc1337" = 1;

    ## TCP optimization
    # Bufferbloat mitigations + slight improvement in throughput & latency
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  # Change me later!
  user.initialPassword = "nixos";
  users.users.root.initialPassword = "nixos";

  # So we don't have to do this later...
  security.acme.acceptTerms = true;
}
