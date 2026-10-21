# test/pinentry/test_pinentry.py --- the pinentry shim
#
# Two layers: a transcript test that drives the shim's stdin/stdout directly
# (with a stand-in for the Quickshell socket), and an end-to-end test that runs
# a real gpg-agent against it, because the agent is the only thing that decides
# whether the escaping, the cancel code and the retry loop are right.
#
#   python3 test/pinentry/test_pinentry.py <repo>

import json
import os
import pty
import shutil
import socket
import subprocess
import sys
import tempfile
import threading

REPO = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else ".")
SHIM = os.path.join(REPO, "config/pinentry/bin/pinentry.py")

failures = []


def check(name, condition, detail=""):
    if condition:
        print("ok   %s" % name)
        return
    print("FAIL %s%s" % (name, (": " + detail) if detail else ""))
    failures.append(name)


class Surface:
    """A stand-in for the Quickshell card: answers every request it is told to."""

    def __init__(self, path, answer):
        self.answer = answer
        self.requests = []
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.sock.bind(path)
        self.sock.listen(8)
        self.thread = threading.Thread(target=self.serve, daemon=True)
        self.thread.start()

    def serve(self):
        while True:
            try:
                conn, _ = self.sock.accept()
            except OSError:
                return
            with conn:
                data = b""
                while b"\n" not in data:
                    chunk = conn.recv(4096)
                    if not chunk:
                        break
                    data += chunk
                if not data:
                    continue
                self.requests.append(json.loads(data.split(b"\n", 1)[0]))
                conn.sendall((json.dumps(self.answer(self.requests[-1])) + "\n").encode())

    def close(self):
        self.sock.close()


def base_env(runtime):
    env = dict(os.environ)
    env["XDG_RUNTIME_DIR"] = runtime
    # No terminal to fall back to: these tests assert the shell path.
    env["GPG_TTY"] = "/nonexistent"
    return env


def run_shim(lines, env):
    proc = subprocess.run(
        [sys.executable, SHIM],
        input="".join(line + "\n" for line in lines),
        capture_output=True,
        text=True,
        env=env,
        timeout=30,
    )
    return proc.stdout.splitlines()


def test_transcript():
    with tempfile.TemporaryDirectory() as runtime:
        env = base_env(runtime)
        out = run_shim(
            [
                "OPTION ttyname=/nonexistent/tty",
                "OPTION allow-external-password-cache",
                "GETINFO pid",
                "GETINFO ttyinfo",
                "SETTITLE Test Title",
                "SETDESC Line one%0ALine %22two%22",
                "SETPROMPT Passphrase:",
                "GETPIN",
                "BYE",
            ],
            env,
        )
        check("greets", out and out[0].startswith("OK"), repr(out[:1]))
        check("answers OPTION", "OK" in out)
        check("answers GETINFO pid with a pid", any(l.startswith("D ") and l[2:].isdigit() for l in out), repr(out))
        check("answers GETINFO ttyinfo with the tty", "D /nonexistent/tty" in out, repr(out))
        check("cancels GETPIN when the shell is gone",
              "ERR 83886179 Operation cancelled" in out, repr(out))
        check("says goodbye", out[-1].startswith("OK"), repr(out[-1:]))


def test_percent():
    with tempfile.TemporaryDirectory() as runtime:
        env = base_env(runtime)
        surface = Surface(os.path.join(runtime, "quickshell-pinentry.sock"), lambda req: {"ok": True, "data": "pa%ss wo\u00e9rd"})
        try:
            out = run_shim(["GETPIN", "BYE"], env)
        finally:
            surface.close()
        check("escapes the secret on the D line",
              "D pa%25ss wo\u00e9rd" in out, repr(out))


def test_surface_roundtrip():
    with tempfile.TemporaryDirectory() as runtime:
        env = base_env(runtime)
        surface = Surface(os.path.join(runtime, "quickshell-pinentry.sock"), lambda req: {"ok": True, "data": "s3cret"})
        try:
            out = run_shim(
                [
                    "SETTITLE Unlock",
                    "SETDESC Please enter the passphrase to unlock the OpenPGP secret key:%0A%22Pin Test%22",
                    "SETPROMPT Passphrase:",
                    "GETPIN",
                    "SETERROR Bad Passphrase (try 2 of 3)",
                    "GETPIN",
                    "BYE",
                ],
                env,
            )
        finally:
            surface.close()
        check("answers GETPIN with the typed secret", out.count("D s3cret") == 2, repr(out))
        check("shows the request in the card",
              surface.requests[0]["desc"] == 'Please enter the passphrase to unlock the OpenPGP secret key:\n"Pin Test"',
              repr(surface.requests[0]))
        check("passes the retry error along",
              surface.requests[1]["error"] == "Bad Passphrase (try 2 of 3)",
              repr(surface.requests[1]))


def test_cancel():
    with tempfile.TemporaryDirectory() as runtime:
        env = base_env(runtime)
        surface = Surface(os.path.join(runtime, "quickshell-pinentry.sock"), lambda req: {"ok": False})
        try:
            out = run_shim(["GETPIN", "BYE"], env)
        finally:
            surface.close()
        check("reports a dismissal as cancelled",
              "ERR 83886179 Operation cancelled" in out, repr(out))


def test_confirm():
    with tempfile.TemporaryDirectory() as runtime:
        env = base_env(runtime)
        answers = [{"ok": True}, {"ok": False}]
        surface = Surface(os.path.join(runtime, "quickshell-pinentry.sock"), lambda req: answers.pop(0))
        try:
            out = run_shim(["SETDESC Sign this key?", "CONFIRM", "CONFIRM", "BYE"], env)
        finally:
            surface.close()
        check("confirms on yes", "OK" in out, repr(out))
        check("rejects on no", "ERR 83886179 Operation cancelled" in out, repr(out))


def test_askpass():
    with tempfile.TemporaryDirectory() as runtime:
        env = base_env(runtime)
        surface = Surface(os.path.join(runtime, "quickshell-pinentry.sock"), lambda req: {"ok": True, "data": "hunter2"})
        try:
            proc = subprocess.run(
                [sys.executable, SHIM, "--askpass", "[sudo] password for gerson: "],
                capture_output=True,
                text=True,
                env=env,
                timeout=30,
            )
        finally:
            surface.close()
        check("askpass prints the secret", proc.stdout == "hunter2\n", repr(proc.stdout))
        check("askpass returns success", proc.returncode == 0)
        check("askpass asks as a pin", surface.requests[0]["kind"] == "pin", repr(surface.requests))


def test_askpass_cancel():
    with tempfile.TemporaryDirectory() as runtime:
        env = base_env(runtime)
        surface = Surface(os.path.join(runtime, "quickshell-pinentry.sock"), lambda req: {"ok": False})
        try:
            proc = subprocess.run(
                [sys.executable, SHIM, "--askpass", "Password:"],
                capture_output=True,
                text=True,
                env=env,
                timeout=30,
            )
        finally:
            surface.close()
        check("askpass fails when dismissed", proc.returncode != 0 and proc.stdout == "",
              repr((proc.returncode, proc.stdout)))


def test_tty_fallback():
    """gpg-agent is detached, so the card being down must fall back to its tty."""
    with tempfile.TemporaryDirectory() as runtime:
        env = base_env(runtime)  # no socket: the shell is gone
        master, slave = pty.openpty()
        tty = os.ttyname(slave)
        proc = subprocess.Popen(
            [sys.executable, SHIM],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            text=True,
            env=env,
        )
        try:
            proc.stdout.readline()  # the greeting
            proc.stdin.write("OPTION ttyname=%s\n" % tty)
            proc.stdin.flush()
            proc.stdout.readline()  # the OPTION's OK
            proc.stdin.write("GETPIN\n")
            proc.stdin.flush()
            prompt = os.read(master, 1024).decode()
            os.write(master, b"s3cret\n")
            data = proc.stdout.readline()
            ok = proc.stdout.readline()
        finally:
            proc.stdin.write("BYE\n")
            proc.stdin.flush()
            proc.wait(10)
            os.close(master)
            os.close(slave)
        check("falls back to the terminal the agent named", prompt.startswith("Passphrase:"), repr(prompt))
        check("returns the typed line", data == "D s3cret\n" and ok == "OK\n", repr((data, ok)))


def test_askpass_tty_fallback():
    """sudo/ssh run in the terminal, so the fallback goes through GPG_TTY."""
    with tempfile.TemporaryDirectory() as runtime:
        env = base_env(runtime)
        master, slave = pty.openpty()
        env["GPG_TTY"] = os.ttyname(slave)
        proc = subprocess.Popen(
            [sys.executable, SHIM, "--askpass", "Password:"],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            text=True,
            env=env,
        )
        try:
            os.read(master, 1024)
            os.write(master, b"hunter2\n")
            out = proc.stdout.read()
            proc.wait(10)
        finally:
            os.close(master)
            os.close(slave)
        check("askpass falls back to the terminal", out == "hunter2\n", repr(out))


def test_gpg_end_to_end(gpg):
    """The real agent: key with a % in the passphrase, signed through the card."""
    with tempfile.TemporaryDirectory() as tmp:
        gnupg = os.path.join(tmp, "gnupg")
        runtime = os.path.join(tmp, "run")
        os.makedirs(gnupg, 0o700)
        os.makedirs(runtime, 0o700)

        surface = Surface(os.path.join(runtime, "quickshell-pinentry.sock"), lambda req: {"ok": True, "data": "pa%ssword"})

        wrapper = os.path.join(tmp, "pinentry")
        with open(wrapper, "w") as f:
            f.write('#!/bin/sh\nexec "%s" "%s" "$@"\n' % (sys.executable, SHIM))
        os.chmod(wrapper, 0o755)

        with open(os.path.join(gnupg, "gpg-agent.conf"), "w") as f:
            f.write("pinentry-program %s\ndefault-cache-ttl 1\n" % wrapper)

        env = dict(os.environ)
        env.update(
            {
                "GNUPGHOME": gnupg,
                "XDG_RUNTIME_DIR": runtime,
                "GPG_TTY": "/nonexistent",
                "HOME": tmp,
            }
        )

        params = os.path.join(tmp, "key.params")
        with open(params, "w") as f:
            f.write(
                "%echo generating\n"
                "Key-Type: RSA\nKey-Length: 2048\n"
                "Name-Real: Pinentry Test\n"
                "Name-Email: pinentry@test.invalid\n"
                "Expire-Date: 0\n"
                "%commit\n%echo done\n"
            )
        passfile = os.path.join(tmp, "pass")
        with open(passfile, "w") as f:
            f.write("pa%ssword")

        made = subprocess.run(
            [gpg, "--batch", "--yes", "--pinentry-mode", "loopback",
             "--passphrase-file", passfile, "--generate-key", params],
            capture_output=True, text=True, env=env, timeout=120,
        )
        check("generates a key", made.returncode == 0, made.stderr)
        if made.returncode != 0:
            surface.close()
            return

        msg = os.path.join(tmp, "msg.txt")
        with open(msg, "w") as f:
            f.write("hello\n")
        signed = subprocess.run(
            [gpg, "--batch", "--yes", "--digest-algo", "SHA256", "--sign", msg],
            capture_output=True, text=True, env=env, timeout=120,
        )
        check("signs through the card", signed.returncode == 0, signed.stderr)
        check("the agent asked the card", len(surface.requests) > 0, repr(surface.requests))
        check("signature exists", os.path.exists(msg + ".gpg"))
        surface.close()


def main():
    for test in (
        test_transcript,
        test_percent,
        test_surface_roundtrip,
        test_cancel,
        test_confirm,
        test_askpass,
        test_askpass_cancel,
        test_tty_fallback,
        test_askpass_tty_fallback,
    ):
        test()

    gpg = shutil.which("gpg")
    if gpg:
        test_gpg_end_to_end(gpg)
    else:
        print("skip gpg end-to-end (no gpg)")

    if failures:
        print("\n%d failed" % len(failures))
        return 1
    print("\nall passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
