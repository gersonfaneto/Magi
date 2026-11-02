## Quick start

1. Acquire or build a NixOS 26.11+ image:

   ```sh
   # Yoink nixos-unstable from upstream
   $ wget -O nixos.iso https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-x86_64-linux.iso
   ```

2. Write it to a USB drive:

   ```sh
   # Replace /dev/sdX with the correct partition!
   $ cp nixos.iso /dev/sdX
   ```

3. Restart and boot into the installer.

4. As root, run the installer. It guides you through hostname, user, role,
   disk, and passwords, scaffolds a host config if needed, partitions with
   disko, and installs:

   ```sh
   nix --extra-experimental-features "nix-command flakes" --option accept-flake-config true run github:gersonfaneto/Magi#install
   ```

   (The flags enable flakes and pre-accept the flake's binary caches, so the
   install never stops to ask.)

   New hosts land as uncommitted files under `hosts/<name>/` (see
   [hosts/README.md](hosts/README.md)): review them, then commit when happy.

   Reinstalling an existing host? Same one-liner: hosts with a `disko.nix`
   repartition themselves, others need `--no-disko` after partitioning and
   mounting to `/mnt` by hand. `install.zsh --help` lists every flag.

5. Reboot!

> [!WARNING]
> Don't forget to change your `root` and `$USER` passwords! They are set to
> `nixos` by default.

## Management

Everything day-to-day goes through `magi`, a control center for this flake
(`magi help` lists every subcommand):

```sh
magi sync switch   # rebuild the system
magi sync build    # ...or just build it
magi test          # janet + nixos test suites
magi gc            # garbage-collect the nix store
magi sup           # what upstream would change
magi pull          # update flake inputs
magi ops push HOST # build here, activate over there
```

## Updating

Inputs are pinned in `flake.lock`. Updating is three steps: see what moved, bump
the pins, then prove the system still builds and tests.

```sh
magi sup            # what upstream has that this system doesn't (read-only)
magi sup -a         # ...every package, not just the ones that moved
magi pull           # update every input
magi pull nixpkgs   # ...or just one (globs work: 'hypr*', '!hyprland')
magi pull -o nixpkgs@<rev>   # repin to a known-good revision
```

Then build and test before touching the running system:

```sh
magi sync build
magi test
nix fmt
```

Commit `flake.lock` on its own, then `magi sync switch`. If it goes wrong,
`git checkout -- flake.lock` and rebuild, or `magi sync rollback`.

If the bump changes Nix itself (a new `nixpkgs` or `nixos-rebuild-ng` pin), the
first sync can wait forever before activating: the new Nix wants to migrate the
store database, which needs the exclusive `big-lock`, while `nix-daemon`
workers hold it shared for as long as their clients (nixd, for one) stay
connected. The unit uses `KillMode=process`, so stopping it leaves those
workers running. Release the store first, then sync:

```sh
sudo systemctl stop nix-daemon.socket
sudo pkill -x nix-daemon        # workers too, not just the main process
magi sync switch
sudo systemctl start nix-daemon.socket
```

The sync only needs root and the local store, so it does not care that the
daemon is down; other `nix` commands fail until it is back.

`magi pull` reuses Nix's cached flake refs (about an hour). For the freshest
commits, refresh explicitly:

```sh
nix flake update --refresh --accept-flake-config --flake /etc/magi
```

`nixpkgs` is pinned to `nixos-unstable` independently of Hyprland's own pin on
purpose; do not add `nixpkgs.follows = "hyprland/nixpkgs"`. Hyprland bumps are
the ones most likely to need edits in `config/hypr/`.

## Frequently asked questions

- **Should I use this?**

  **Short answer:** no.

  It's one person's workstation config, with strong opinions and no interest
  in being general. If anything here helps you, steal the idea, not the code.
  And if all else fails, ask for help on [the NixOS Discourse][nixos-discourse].

- **How do you manage secrets?**

  With [agenix]: per-host rules in `hosts/<name>/secrets/`, decrypted with
  the host key. New hosts get an empty rules file; provision the key with
  `magi ops push-keys <name>` before the first boot that needs a secret (see
  [hosts/README.md](hosts/README.md)).

[agenix]: https://github.com/ryantm/agenix
[nixos-discourse]: https://discourse.nixos.org
