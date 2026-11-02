# test/nixos/modules/dev.nix --- tests for modules/dev/
#
# Every language module carries an xdg.enable option that defaults to
# modules.dev.xdg.enable. The defaults are read here because a typo in one of
# them only shows up when something forces the option, and today nothing does.
{evalConfig, ...}: let
  lua = evalConfig [{modules.dev.lua.enable = true;}];
in {
  testLuaXdgFollowsDev = {
    expr = lua.modules.dev.lua.xdg.enable;
    expected = lua.modules.dev.xdg.enable;
  };

  # modules.dev.xdg.enable follows the global switch, which is on by default.
  testDevXdgDefaultsToGlobal = {
    expr = {
      dev = lua.modules.dev.xdg.enable;
      global = lua.modules.xdg.enable;
    };
    expected = {
      dev = true;
      global = true;
    };
  };
}
