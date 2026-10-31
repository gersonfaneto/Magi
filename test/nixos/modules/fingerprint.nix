# test/nixos/modules/fingerprint.nix --- tests for modules/profiles/hardware/fingerprint.nix
#
# The lock screen and greeter each get their own PAM story: the lock runs
# fingerprint and password as separate transactions, so its scan service must
# not fall through to pam_unix; greetd opts out of the default rules and needs
# the scan inserted before its login substack. Everything else is about not
# parking a password behind the reader.
{
  evalConfig,
  lib,
  ...
}:
with lib; let
  on = evalConfig [{modules.profiles.hardware = ["fingerprint"];}];

  greetd = evalConfig [
    {
      modules.profiles.hardware = ["fingerprint"];
      services.greetd.enable = true;
    }
  ];

  lock = on.security.pam.services.magi-lock-fingerprint;
  greetdAuth = greetd.security.pam.services.greetd.rules.auth;
in {
  testFprintdIsEnabled = {
    expr = on.services.fprintd.enable;
    expected = true;
  };

  # A password typed while the sensor scans runs in its own transaction. This
  # service must only ever wait on the reader, never on pam_unix.
  testLockScanDoesNotFallBackToPassword = {
    expr = {
      fingerprint = lock.rules.auth.fprintd.enable;
      password = lock.rules.auth.unix.enable;
    };
    expected = {
      fingerprint = true;
      password = false;
    };
  };

  # The lock's password transaction, getty and remote logins must answer
  # immediately instead of sitting through pam_fprintd's timeout.
  testPasswordServicesSkipFingerprint = {
    expr = {
      login = on.security.pam.services.login.fprintAuth;
      sshd = on.security.pam.services.sshd.fprintAuth;
      passwd = on.security.pam.services.passwd.fprintAuth;
    };
    expected = {
      login = false;
      sshd = false;
      passwd = false;
    };
  };

  # Explicit fingerprint prompts keep the reader, but on a shorter leash than
  # the 30s default.
  testSudoAndPolkitKeepAShortScan = {
    expr = {
      sudo = on.security.pam.services.sudo.rules.auth.fprintd.settings.timeout;
      polkit = on.security.pam.services.polkit-1.rules.auth.fprintd.settings.timeout;
      su = on.security.pam.services.su.rules.auth.fprintd.settings.timeout;
    };
    expected = {
      sudo = 10;
      polkit = 10;
      su = 10;
    };
  };

  # greetd's stack is its own, so it needs an explicit fprintd rule; it has to
  # run before the login substack or the password prompt always wins.
  testGreeterScansBeforePassword = {
    expr = {
      hasScan = greetdAuth ? fprintd;
      beforeLogin = greetdAuth.fprintd.order < greetdAuth.login.order;
      sufficient = greetdAuth.fprintd.control;
    };
    expected = {
      hasScan = true;
      beforeLogin = true;
      sufficient = "sufficient";
    };
  };
}
