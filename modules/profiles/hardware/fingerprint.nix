# profiles/hardware/fingerprint.nix --- fprintd and PAM wiring for the reader
#
# The lock screen authenticates fingerprints and passwords as separate PAM
# transactions (see config/quickshell/lock/Auth.qml). PAM serialises modules,
# so putting pam_fprintd in front of pam_unix on a service the lock uses would
# park every typed password behind a scan. The dedicated magi-lock-fingerprint
# service therefore has no pam_unix fallback, while login stays password-only.
#
# The graphical greeter gets its own fprintd rule instead: greetd opts out of
# NixOS's default PAM rules and authenticates through a login substack, so it
# would otherwise never see the reader.
{
  self,
  lib,
  config,
  ...
}:
with lib;
with self.lib; let
  # A fingerprint here only delays the password prompt: remote logins cannot
  # reach the reader, login covers getty and the lock's password transaction,
  # and the rest are account management or lockers this flake does not use.
  passwordOnly = [
    "chfn"
    "chpasswd"
    "chsh"
    "groupadd"
    "groupdel"
    "groupmems"
    "groupmod"
    "i3lock"
    "i3lock-color"
    "login"
    "other"
    "passwd"
    "runuser"
    "runuser-l"
    "sshd"
    "swaylock"
    "systemd-run0"
    "systemd-user"
    "useradd"
    "userdel"
    "usermod"
    "vlock"
    "xlock"
    "xscreensaver"
  ];
in
  mkIf (elem "fingerprint" config.modules.profiles.hardware) (mkMerge [
    {
      services.fprintd.enable = true;

      security.pam.services =
        {
          # The lock screen's scan. No unixAuth: a failed or ignored scan must
          # end, not turn into a password prompt inside this transaction. The
          # lock retries it on its own.
          magi-lock-fingerprint = {
            unixAuth = false;
            rules.auth.fprintd.settings = {
              timeout = 30;
              "max-tries" = 3;
            };
          };

          # Explicit finger at these prompts, but a short window: ignoring the
          # sensor should not stall the password by pam_fprintd's 30s default.
          sudo.rules.auth.fprintd.settings.timeout = 10;
          su.rules.auth.fprintd.settings.timeout = 10;
          polkit-1.rules.auth.fprintd.settings.timeout = 10;
        }
        // genAttrs passwordOnly (name: {
          fprintAuth = false;
        });
    }

    # greetd's own auth stack is a substack of login; place the scan before it
    # so the greeter can try a finger first, then fall back to the password.
    (mkIf config.services.greetd.enable {
      security.pam.services.greetd.rules.auth.fprintd = {
        control = "sufficient";
        modulePath = "${config.services.fprintd.package}/lib/security/pam_fprintd.so";
        settings = {
          timeout = 10;
          "max-tries" = 1;
        };
        order = config.security.pam.services.greetd.rules.auth.login.order - 10;
      };
    })
  ])
