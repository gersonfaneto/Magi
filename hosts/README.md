# hosts/

Host configs live here, one directory per machine (`hosts/<name>/default.nix`).
Only `melchior` is tracked in git — this directory is otherwise a **whitelist**
(see `.gitignore`): scaffolded and experimental hosts stay local until they're
worth keeping.

## Adding a machine

Boot the installer ISO and run, as root:

```sh
nix --extra-experimental-features "nix-command flakes" --option accept-flake-config true run github:gersonfaneto/Magi#install
```

It guides you through hostname, user, role, disk, and passwords, then:

1. scaffolds `hosts/<name>/` (a `default.nix` pinning
   `installer/host-template.nix`, a `disko.nix` pinning the target disk, a
   captured `hardware-configuration.nix`, and starter `secrets/secrets.nix`)
   as **uncommitted** files, and `git add`s them (staged, so flake evaluation
   sees the new host — raw untracked files are invisible to it),
2. partitions the disk with disko (default layout: 1G ESP + 8G swap + root),
3. runs `nixos-install` for the new host.

Review the scaffold, adjust it (monitors, extra mounts, secrets), and commit
it when happy. `install.zsh --help` documents the non-interactive flags
(`--disk`, `--role`, `--yes`, `--dry-run`, ...).

This whole flow is verified end-to-end: a stock ISO in QEMU ran the
one-liner against a blank disk (scaffold → disko → `nixos-install`), and the
result kexec-booted to a login as the scaffolded host.

## Notes

- Fresh hosts are fully disko-managed: don't hand-write `fileSystems` for
  them. `melchior` included: its `disko.nix` mirrors the live disk (by-label
  addressing, since the partitions were never GPT-named), so it reinstalls
  through the normal disko flow. Only hosts that predate disko need
  `install.zsh --no-disko` after partitioning by hand.
- The installer targets UEFI + `systemd-boot`. BIOS, LUKS, RAID, and other
  exotic layouts stay manual: partition by hand, write the host, re-run.
- Secrets live in `hosts/<name>/secrets/secrets.nix` (agenix rules) and are
  decrypted with the host key at `/etc/ssh/host_ed25519`. The scaffold ships
  an empty rules file with the full flow in its header (`installer/secrets.nix`):
  add entries, commit, then provision the host key from your admin machine
  *before* the first boot that needs them — `magi ops push-keys <name>` —
  because activation refuses to boot when secrets exist without their host
  key. See the FAQ in the main README.
