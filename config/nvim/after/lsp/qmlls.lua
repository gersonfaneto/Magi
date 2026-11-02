-- QML language server from Qt Declarative
-- https://doc.qt.io/qt-6/qtqml-tooling-qmlls.html

-- `-E` also reads QML_IMPORT_PATH. modules/editors/vim.nix uses it to expose
-- the Quickshell/QtMultimedia/Qt5Compat module dirs, so `import Quickshell.*`
-- resolves outside a CMake project. Each vendored shell has its own
-- shell.qml, so the surface dir (not the repo's .git root) becomes the root.
---@type minimal.lsp.config
return {
  cmd = { 'qmlls', '-E' },
  filetypes = { 'qml' },
  root_markers = { 'CMakeLists.txt', '.qmlls.ini', 'qmldir', 'shell.qml' },
}
