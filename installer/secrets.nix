# installer/secrets.nix --- the secrets rules new hosts start with
#
# install.zsh copies this to hosts/<name>/secrets/secrets.nix when it
# scaffolds a host. Empty on purpose: add entries as this machine earns
# secrets, following the shape below.
#
# The flow, end to end:
#
#   1. Add an entry here and put the .age file beside it, e.g.
#
#        "wifi-password" = {
#          publicKeys = [ host user ];
#          file = "wifi-password.age";
#        };
#
#      where `host` is this machine's age key and `user` is yours (see
#      config/secrets/secrets.nix for a lived-in example). Create the .age
#      file with `agenix -e hosts/<name>/secrets/<file>.age` from a machine
#      that already decrypts it.
#
#   2. Commit both files.
#
#   3. Provision this machine's host key (/etc/ssh/host_ed25519, which age
#      decrypts with) from your admin machine BEFORE the first boot that
#      needs the secret:
#
#        hey ops push-keys <name>
#
#      The activation script refuses to boot a system whose secrets exist but
#      whose host key is missing (see modules/agenix.nix), so don't skip this.
#
#   4. `hey sync switch` (or reinstall) to pick the secret up.
let
  # This machine's age public key (an ssh-ed25519... string). Fill in once
  # the host key exists; every entry below should list it.
  host = "";
  # Your own age public key, so you can re-encrypt without the machine.
  user = "";
in {}
