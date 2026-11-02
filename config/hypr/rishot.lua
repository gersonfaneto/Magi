-- config/hypr/rishot.lua
--
-- Screenshots through the vendored rishot. The clipboard-first region shot is
-- the Magi default; SHIFT+Print opens the full editor.

hl.bind('Print', hl.dsp.exec_cmd('rishot --clipboard'))
hl.bind('SHIFT + Print', hl.dsp.exec_cmd('rishot'))
