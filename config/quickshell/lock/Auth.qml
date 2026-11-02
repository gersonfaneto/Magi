import QtQuick
import Quickshell.Services.Pam

/**
 * Lock authentication.
 *
 * PAM serialises its modules, so fingerprint and password run as two separate
 * transactions instead of one stack: a scan can run in the background while
 * the password field stays usable, and submitting a password aborts the scan
 * instead of waiting for it to time out. magi-lock-fingerprint is defined in
 * modules/profiles/hardware/fingerprint.nix; login is password-only there, so
 * this password transaction never blocks on the reader.
 */
Item {
    id: auth

    property string user: ""

    /** A password transaction is running; the capsule dims for it. */
    readonly property bool authenticating: pam.active
    /** The fingerprint transaction is running. */
    readonly property bool fingerprinting: finger.active
    /** Latest message the reader sent, for the lock's hint / error text. */
    readonly property string fingerprintMessage: finger.message

    signal failed
    signal succeeded

    property string pendingPassword: ""
    property string lastError: ""
    property bool open: false

    /** The last scan ran to completion without a match. */
    property bool fingerprintFailed: false
    /** PAM could not start the scan at all (no service, no reader, no prints). */
    property bool fingerprintUnavailable: false

    /** Start scanning when the lock surface opens. */
    function begin(): void {
        auth.open = true;
        auth.lastError = "";
        auth.pendingPassword = "";
        auth.fingerprintFailed = false;
        auth.fingerprintUnavailable = false;
        if (!finger.active)
            finger.start();
    }

    /** Forget the last failure and run a fresh scan, for the icon's tap. */
    function rescan(): void {
        auth.lastError = "";
        auth.fingerprintFailed = false;
        auth.fingerprintUnavailable = false;
        if (finger.active)
            finger.abort();
        rescanTimer.restart();
    }

    /** Stop both transactions when the lock closes or the session unlocks. */
    function stop(): void {
        auth.open = false;
        auth.pendingPassword = "";
        auth.fingerprintFailed = false;
        auth.fingerprintUnavailable = false;
        if (finger.active)
            finger.abort();
        if (pam.active)
            pam.abort();
    }

    function submit(password): void {
        if (pam.active && pam.responseRequired) {
            pam.respond(password);
            return;
        }
        auth.lastError = "";
        if (finger.active)
            finger.abort();
        if (pam.active)
            pam.abort();
        auth.pendingPassword = password;
        pam.start();
    }

    Timer {
        id: retry
        interval: 1000
        onTriggered: if (auth.open && !finger.active) {
            auth.fingerprintFailed = false;
            finger.start();
        }
    }

    Timer {
        id: rescanTimer
        interval: 120
        onTriggered: if (auth.open && !finger.active)
            finger.start()
    }

    PamContext {
        id: finger
        config: "magi-lock-fingerprint"
        user: auth.user

        onPamMessage: {
            if (messageIsError && message.length > 0)
                auth.lastError = message;
        }

        onCompleted: result => {
            if (!auth.open)
                return;
            if (result === PamResult.Success) {
                auth.open = false;
                auth.succeeded();
                return;
            }
            auth.fingerprintFailed = true;
            retry.restart();
        }

        onError: {
            auth.fingerprintFailed = false;
            auth.fingerprintUnavailable = true;
        }
    }

    PamContext {
        id: pam
        config: "login"
        user: auth.user

        onResponseRequiredChanged: {
            if (responseRequired)
                respond(auth.pendingPassword);
        }

        onPamMessage: {
            if (messageIsError && message.length > 0)
                auth.lastError = message;
        }

        onCompleted: result => {
            auth.pendingPassword = "";
            if (result === PamResult.Success) {
                auth.open = false;
                auth.succeeded();
                return;
            }
            auth.failed();
            if (auth.open)
                retry.restart();
        }

        onError: {
            auth.pendingPassword = "";
            auth.failed();
            if (auth.open)
                retry.restart();
        }
    }
}
