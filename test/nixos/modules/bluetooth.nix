# test/nixos/modules/bluetooth.nix --- tests for modules/profiles/hardware/bluetooth.nix
#
# bluetoothd rejects every pairing that needs a confirmation unless an agent is
# registered, and bluetoothctl only auto-registers one in interactive mode
# (client/main.c skips it whenever commands are passed as arguments). Pin the
# unit that keeps an agent around, and that the profile no longer disables
# BlueZ's reconnection policy.
{
  evalConfig,
  lib,
  ...
}:
with lib; let
  on = evalConfig [{modules.profiles.hardware = ["bluetooth"];}];
  agent = on.systemd.user.services.bluetooth-agent;
in {
  testBluetoothEnabled = {
    expr = on.hardware.bluetooth.enable;
    expected = true;
  };

  # Without this, the pill's `bluetoothctl pair` (and any device bonding on
  # its own) has no agent to confirm the passkey with.
  testPairingAgentRunsForTheSession = {
    expr = {
      wantedBy = agent.wantedBy;
      restarts = agent.serviceConfig.Restart;
      justWorks = hasInfix "--agent=NoInputNoOutput" agent.serviceConfig.ExecStart;
    };
    expected = {
      wantedBy = ["default.target"];
      restarts = "always";
      justWorks = true;
    };
  };

  # 0 means "never reconnect"; the profile used to pin that.
  testReconnectAttemptsIsNotDisabled = {
    expr = on.hardware.bluetooth.settings.Policy.ReconnectAttempts or null;
    expected = null;
  };
}
