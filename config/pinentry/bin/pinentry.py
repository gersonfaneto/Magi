#!/usr/bin/env python3
# config/pinentry/bin/pinentry.py
#
# A pinentry front end that draws in the Quickshell shell
# (config/pinentry/surface) instead of popping a stock Qt dialog.
#
# gpg-agent spawns this with no arguments of its own and talks the pinentry
# protocol over stdin/stdout; every request is handed to the surface over a
# Unix socket in $XDG_RUNTIME_DIR, which answers with the typed secret. The
# passphrase never touches the disk. `--askpass` turns the same card into the
# SSH_ASKPASS/SUDO_ASKPASS shape, which prints the secret on stdout.
#
# When the shell isn't reachable (a TTY session, or the service is down) this
# falls back to reading from the terminal so gpg, ssh and sudo keep working.

import json
import os
import socket
import sys
import termios

# $XDG_RUNTIME_DIR/<name>; the surface listens here (config/pinentry/surface/shell.qml).
SOCKET = "quickshell-pinentry.sock"
# The agent gives up on its own eventually; this keeps a dead client from
# blocking the card forever if the shell never answers.
ASK_TIMEOUT = 300.0
# GPG_ERR_CANCELED, as every pinentry sends when the user backs out.
CANCELLED = "83886179"

# The strings the agent sets; everything else it sends is a no-op we can wave
# through (SETQUALITYBAR, SETTIMEOUT, NOP, ...). Keys are the protocol names.
FIELDS = {
    "SETDESC": "desc",
    "SETPROMPT": "prompt",
    "SETTITLE": "title",
    "SETERROR": "error",
    "SETOK": "ok",
    "SETCANCEL": "cancel",
    "SETREPEAT": "repeat",
}


def blank_state():
    return dict.fromkeys(FIELDS.values(), "") | {"ttyname": ""}


def runtime_dir():
    return os.environ.get("XDG_RUNTIME_DIR") or "/run/user/%d" % os.getuid()


def socket_path():
    return os.path.join(runtime_dir(), SOCKET)


def percent_decode(text):
    """Undo the agent's %XX escaping on the strings it sends."""
    raw = text.encode()
    out = bytearray()
    i = 0
    while i < len(raw):
        if raw[i] == 0x25 and i + 2 < len(raw):  # '%'
            try:
                out.append(int(raw[i + 1:i + 3].decode("ascii"), 16))
            except (ValueError, UnicodeDecodeError):
                out.append(raw[i])
                i += 1
                continue
            i += 3
            continue
        out.append(raw[i])
        i += 1
    return out.decode("utf-8", "replace")


def percent_encode(text):
    """Escape a secret for the D line; the agent unescapes it again."""
    out = []
    for ch in text:
        if ch == "%":
            out.append("%25")
        elif ch == "\n":
            out.append("%0A")
        elif ch == "\r":
            out.append("%0D")
        elif ord(ch) < 0x20 or ord(ch) == 0x7F:
            out.append("%%%02X" % ord(ch))
        else:
            out.append(ch)
    return "".join(out)


def reply(line):
    sys.stdout.write(line + "\n")
    sys.stdout.flush()


def ask_surface(request, timeout=ASK_TIMEOUT):
    """Show REQUEST in the shell. Returns its reply, or None if it isn't there."""
    path = socket_path()
    if not os.path.exists(path):
        return None
    conn = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    conn.settimeout(timeout)
    buf = b""
    try:
        conn.connect(path)
        conn.sendall((json.dumps(request) + "\n").encode())
        while b"\n" not in buf:
            chunk = conn.recv(4096)
            if not chunk:
                return None
            buf += chunk
    except OSError:
        return None
    finally:
        conn.close()
    try:
        return json.loads(buf.split(b"\n", 1)[0].decode())
    except ValueError:
        return None


def tty_name(agent_tty=""):
    """The terminal to fall back to.

    gpg-agent runs detached, so /dev/tty is not ours to open: it names the
    user's terminal in `OPTION ttyname=` instead. Askpass callers (sudo, ssh)
    are children of the terminal process, so the environment or /dev/tty
    works there.
    """
    return agent_tty or os.environ.get("GPG_TTY") or "/dev/tty"


def ask_tty(prompt, agent_tty="", secret=True):
    """Read SECRET from the terminal; None when there is no terminal to ask."""
    try:
        fd = os.open(tty_name(agent_tty), os.O_RDWR | os.O_NOCTTY)
    except OSError:
        return None
    old = None
    try:
        if secret and os.isatty(fd):
            old = termios.tcgetattr(fd)
            quiet = termios.tcgetattr(fd)
            quiet[3] &= ~termios.ECHO
            termios.tcsetattr(fd, termios.TCSAFLUSH, quiet)
        os.write(fd, (prompt + " ").encode())
        data = b""
        while not data.endswith(b"\n"):
            ch = os.read(fd, 1)
            if not ch:
                break
            data += ch
    finally:
        if old is not None:
            termios.tcsetattr(fd, termios.TCSAFLUSH, old)
            os.write(fd, b"\n")
        os.close(fd)
    return data.decode("utf-8", "replace").rstrip("\r\n")


def request(kind, **fields):
    return {
        "kind": kind,
        "title": fields.get("title") or "",
        "desc": fields.get("desc") or "",
        "prompt": fields.get("prompt") or "",
        "error": fields.get("error") or "",
        "ok": fields.get("ok") or "",
        "cancel": fields.get("cancel") or "",
        "source": fields.get("source") or "gpg",
    }


def prompt_user(req, agent_tty=""):
    """Return (answered, text); a missing shell falls back to the terminal."""
    answer = ask_surface(req)
    if answer is not None:
        if answer.get("ok"):
            return True, str(answer.get("data") or "")
        return False, ""
    if req["kind"] != "pin":
        return False, ""
    text = ask_tty(req["prompt"] or req["desc"] or "Passphrase:", agent_tty)
    if text is None:
        return False, ""
    return True, text


def read_pin(state):
    """Ask for the passphrase, honouring SETREPEAT's confirmation."""
    req = request(
        "pin",
        title=state["title"] or "PASSPHRASE",
        desc=state["desc"],
        prompt=state["prompt"] or "Passphrase:",
        error=state["error"],
        ok=state["ok"] or "Unlock",
        cancel=state["cancel"] or "Cancel",
    )
    if not state["repeat"]:
        answered, value = prompt_user(req, state["ttyname"])
        return value if answered else None
    # A new passphrase is typed twice; keep asking until they match, like
    # pinentry does, instead of bouncing the mismatch back to gpg.
    for _ in range(3):
        answered, first = prompt_user(req, state["ttyname"])
        if not answered:
            return None
        confirm = dict(req)
        confirm["desc"] = percent_decode(state["repeat"])
        confirm["error"] = ""
        confirm["prompt"] = "Repeat passphrase:"
        answered, second = prompt_user(confirm, state["ttyname"])
        if not answered:
            return None
        if first == second:
            return first
        req["error"] = "The passphrases did not match."
    return None


def run_pinentry():
    state = blank_state()
    reply("OK Pleased to meet you")
    while True:
        line = sys.stdin.readline()
        if not line:
            return 0
        line = line.rstrip("\r\n")
        if not line:
            continue
        name, _, rest = line.partition(" ")
        name = name.upper()

        if name == "BYE":
            reply("OK closing connection")
            return 0
        if name == "GETPIN":
            value = read_pin(state)
            if value is None:
                reply("ERR %s Operation cancelled" % CANCELLED)
            else:
                reply("D " + percent_encode(value))
                reply("OK")
            continue
        if name == "CONFIRM":
            answered, _ = prompt_user(
                request(
                    "confirm",
                    title=state["title"] or "CONFIRM",
                    desc=state["desc"],
                    error=state["error"],
                    ok=state["ok"] or "Confirm",
                    cancel=state["cancel"] or "Cancel",
                ),
                state["ttyname"],
            )
            reply("OK" if answered else "ERR %s Operation cancelled" % CANCELLED)
            continue
        if name == "MESSAGE":
            prompt_user(
                request(
                    "message",
                    title=state["title"] or "NOTICE",
                    desc=state["desc"],
                    ok=state["ok"] or "OK",
                ),
                state["ttyname"],
            )
            reply("OK")
            continue
        if name == "GETINFO":
            item = rest.strip()
            if item == "pid":
                reply("D %d" % os.getpid())
            elif item == "version":
                reply("D 1.0")
            elif item == "flavor":
                reply("D quickshell")
            elif item == "ttyinfo":
                reply("D " + (state["ttyname"] or tty_name()))
            reply("OK")
            continue
        if name == "OPTION":
            if rest.startswith("ttyname="):
                state["ttyname"] = rest[len("ttyname="):]
            reply("OK")
            continue
        if name == "RESET":
            state = blank_state()
            reply("OK")
            continue
        if name in FIELDS:
            state[FIELDS[name]] = percent_decode(rest)
            reply("OK")
            continue
        reply("OK")


def askpass(argv):
    prompt = " ".join(argv).strip() or "Password:"
    parent = ""
    try:
        with open("/proc/%d/comm" % os.getppid()) as f:
            parent = f.read().strip()
    except OSError:
        pass
    if parent == "sudo":
        source = "sudo"
    elif parent.startswith("ssh"):
        source = "ssh"
    else:
        source = "askpass"
    answered, value = prompt_user(
        request(
            "pin",
            title=source.upper(),
            desc=prompt.rstrip(": "),
            prompt=prompt,
            ok="Authenticate",
            cancel="Cancel",
            source=source,
        )
    )
    if not answered:
        return 1
    sys.stdout.write(value + "\n")
    sys.stdout.flush()
    return 0


def main(argv):
    if "--askpass" in argv or "-a" in argv:
        return askpass([arg for arg in argv if arg not in ("--askpass", "-a")])
    return run_pinentry()


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except KeyboardInterrupt:
        sys.exit(1)
