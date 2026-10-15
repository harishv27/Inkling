import Foundation
import LocalAuthentication
import Observation

/// Face ID / Touch ID / passcode lock for the whole journal. The journal locks every time the app goes to
/// the background.
@MainActor @Observable
final class AppLock {
    private static let key = "lockEnabled"

    private(set) var isEnabled: Bool
    private(set) var isLocked: Bool
    private(set) var isAuthenticating = false

    init() {
        let enabled = UserDefaults.standard.bool(forKey: Self.key)
        isEnabled = enabled
        isLocked = enabled
    }

    /// Turning the lock on needs a successful check first, so you can't lock yourself out with a broken setup.
    func setEnabled(_ on: Bool) async -> Bool {
        guard on else {
            isEnabled = false
            isLocked = false
            UserDefaults.standard.set(false, forKey: Self.key)
            return true
        }
        guard await authenticate(reason: "Turn on the journal lock") else { return false }
        isEnabled = true
        UserDefaults.standard.set(true, forKey: Self.key)
        return true
    }

    func lockIfNeeded() { if isEnabled { isLocked = true } }

    func unlock() async {
        guard isLocked, !isAuthenticating else { return }
        if await authenticate(reason: "Unlock your journal") { isLocked = false }
    }

    private func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        // `.deviceOwnerAuthentication` falls back to the passcode when biometrics fail or aren't set up.
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { return false }
        isAuthenticating = true
        defer { isAuthenticating = false }
        return (try? await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)) ?? false
    }
}
