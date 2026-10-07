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
magi pull          # update flake inputs
magi ops push HOST # build here, activate over there
```

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
