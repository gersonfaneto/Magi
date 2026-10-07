local M = {}
local un = require('minimal.utils.snip.nodes')
local us = require('minimal.utils.snip.snips')
local ls = require('luasnip')
local i = ls.insert_node
local c = ls.choice_node

M.snippets = {
  us.msn(
    {
      { trig = 'mod' },
      { trig = 'module' },
      common = { desc = 'NixOS module skeleton' },
    },
    un.fmtad(
      [[
        { config, lib, pkgs, ... }:

        with lib;

        let
          cfg = config.<path>;
        in
        {
          options.<path> = {
            enable = mkEnableOption '<name>';
          };

          config = mkIf cfg.enable {
            <body>
          };
        }
      ]],
      {
        path = i(1, 'modules.path'),
        name = i(2, 'name'),
        body = un.body(3, 1),
      }
    )
  ),
  us.sn(
    {
      trig = 'let',
      desc = 'let ... in expression',
    },
    un.fmtad(
      [[
        let
          <bindings>
        in
        <body>
      ]],
      {
        bindings = i(1, 'x = 1;'),
        body = un.body(2, 0),
      }
    )
  ),
  us.sn(
    {
      trig = 'inherit',
      desc = 'inherit statement',
    },
    un.fmtad('inherit (<scope>) <names>;', {
      scope = i(1, 'pkgs'),
      names = i(2, 'name'),
    })
  ),
  us.msn(
    {
      { trig = 'mkif' },
      { trig = 'if' },
      common = { desc = 'lib.mkIf conditional config' },
    },
    un.fmtad('lib.mkIf <cond> {<body>} ', {
      cond = i(1, 'cfg.enable'),
      body = un.body(2, 0),
    })
  ),
  us.sn(
    {
      trig = 'mkmerge',
      desc = 'lib.mkMerge merged config list',
    },
    un.fmtad(
      [[
        lib.mkMerge [
          <body>
        ]
      ]],
      {
        body = un.body(1, 1),
      }
    )
  ),
  us.msn(
    {
      { trig = 'mkdef' },
      { trig = 'mkdefault' },
      common = { desc = 'lib.mkDefault overridable value' },
    },
    un.fmtad('lib.mkDefault <val>', {
      val = i(1, 'value'),
    })
  ),
  us.msn(
    {
      { trig = 'mkforce' },
      { trig = 'mkForce' },
      common = { desc = 'lib.mkForce forced value' },
    },
    un.fmtad('lib.mkForce <val>', {
      val = i(1, 'value'),
    })
  ),
  us.msn(
    {
      { trig = 'fun' },
      { trig = 'fn' },
      { trig = 'lam' },
      common = { desc = 'Lambda (function) expression' },
    },
    c(1, {
      un.fmtad('{ <args>, ... }:<body>', {
        args = i(1, 'a'),
        body = un.body(2, 0),
      }),
      un.fmtad('<arg>:<body>', {
        arg = i(1, 'x'),
        body = un.body(2, 0),
      }),
    })
  ),
  us.sn(
    {
      trig = 'with',
      desc = 'with expression scope',
    },
    un.fmtad('with <scope>; <body>', {
      scope = i(1, 'pkgs'),
      body = i(2),
    })
  ),
  us.sn(
    {
      trig = 'flake',
      desc = 'flake.nix skeleton',
    },
    un.fmtad(
      [[
        {
          description = '<desc>';

          inputs = {
            nixpkgs.url = 'github:NixOS/nixpkgs/<ref>';
          };

          outputs = { self, nixpkgs, ... }@inputs: {
            <body>
          };
        }
      ]],
      {
        desc = i(1, 'description'),
        ref = i(2, 'nixos-unstable'),
        body = un.body(3, 1),
      }
    )
  ),
  us.sn(
    {
      trig = 'assert',
      desc = 'assert statement',
    },
    un.fmtad('assert <cond>; <body>', {
      cond = i(1, 'cond'),
      body = un.body(2, 0),
    })
  ),
}

return M
