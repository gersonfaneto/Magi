const path = require("node:path");
const os = require("node:os");

// Resolve the custom rule set from $XDG_CONFIG_HOME/markdownlint. This file is
// snapshotted to ~/.markdownlint-cli2.cjs (modules/ai/opencode.nix), so a
// literal `./.config/...` would only work while XDG_CONFIG_HOME happens to be
// ~/.config; prefer the env var when it is set.
const rulesDir = path.join(
  process.env.XDG_CONFIG_HOME || path.join(os.homedir(), ".config"),
  "markdownlint",
);

const noNumberedHeadings = require(path.join(rulesDir, "no-numbered-headings.cjs"));
const tightLists = require(path.join(rulesDir, "tight-lists.cjs"));
const noNbsp = require(path.join(rulesDir, "no-nbsp.cjs"));
const alignedTables = require(path.join(rulesDir, "aligned-tables.cjs"));
const hardWrap = require(path.join(rulesDir, "hard-wrap.cjs"));

module.exports = {
  config: {
    default: false,
    MD009: {
      br_spaces: 0,
      code_blocks: true,
    },
    MD022: true,
    MD030: {
      severity: "warning",
      ul_single: 1,
      ol_single: 1,
      ul_multi: 1,
      ol_multi: 1,
    },
    MD041: false,
    "no-numbered-headings": {
      severity: "warning",
    },
    "tight-lists": {
      severity: "warning",
    },
    "no-nbsp": {
      ignore_trailing: true,
    },
    "aligned-tables": {
      severity: "warning",
    },
    "hard-wrap": {
      severity: "warning",
      line_length: 79,
    },
  },
  customRules: [noNumberedHeadings, tightLists, noNbsp, alignedTables, hardWrap],
};
