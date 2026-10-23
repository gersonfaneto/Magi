# config/qutebrowser/config.py
#
# Linked into ~/.config/qutebrowser/config.py by
# modules/apps/browsers/qutebrowser.nix, so `:config-source` picks up edits
# without a rebuild. Runtime `:set` values land in autoconfig.yml beside it,
# which stays out of the checkout.

from pathlib import Path

config.load_autoconfig()

# The palette-derived colours are rendered into ~/.config/qutebrowser/theme.py
# by the theme pipeline. It may not exist until the first `magi theme`.
theme = Path(config.configdir) / "theme.py"
if theme.exists():
    config.source(str(theme))

# Same engine as chromium's policy (modules/apps/browsers/chromium.nix).
c.url.searchengines = {"DEFAULT": "https://noai.duckduckgo.com/?q={}"}
c.url.default_page = "about:blank"
c.url.start_pages = ["about:blank"]

# The Brave ABP-style blocker (nixpkgs ships the `adblock` package) is the
# resolved `auto` method, with EasyList and EasyPrivacy as its defaults; run
# `:adblock-update` to refresh them. Do not set `both`: the hosts blocker needs
# a writable /etc/hosts.
c.content.blocking.enabled = True
c.content.notifications.enabled = False
c.content.geolocation = False
c.content.javascript.clipboard = "access"
c.content.webrtc_ip_handling_policy = "default_public_interface_only"

# Needs QtWebEngine dictionaries to do anything; check `:version` if it looks
# inert.
c.spellcheck.languages = ["en-US", "pt-BR"]

# Wayland by default, and qt6ct explicitly so the Qt palette doesn't depend on
# how the session splits QT_QPA_PLATFORMTHEME across Qt5/Qt6.
c.qt.force_platform = "wayland"
c.qt.force_platformtheme = "qt6ct"
c.colors.webpage.preferred_color_scheme = "auto"

c.downloads.location.directory = "~/Downloads"
c.downloads.location.prompt = False
c.downloads.remove_finished = 60000

c.auto_save.session = True
c.session.lazy_restore = True
c.tabs.last_close = "startpage"
c.scrolling.smooth = True

# Open the page under the cursor in a terminal editor.
c.editor.command = ["foot", "-e", "nvim", "{file}"]

c.aliases = {
    "q": "close",
    "qa": "quit",
    "w": "session-save",
    "wq": "quit --save",
    "wqa": "quit --save",
    "mpv": "spawn mpv {url}",
}

# Re-source config.py and the rendered theme after a palette change. The Qt
# palette itself only follows after `:restart`.
config.bind("<Ctrl-Alt-r>", "config-source")
