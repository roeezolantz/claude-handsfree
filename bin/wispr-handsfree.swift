import ApplicationServices
import CoreGraphics
import Foundation
// Default: send Fn+Space (Wispr Flow hands-free toggle). "tap": Fn alone, ends any running dictation. "enter": Return.
let args = CommandLine.arguments.dropFirst()
if args.first == "--help" || args.first == "-h" {
    print("""
    wispr-handsfree [tap|enter|--help]

    Sends macOS key events via CGEvent to drive Wispr Flow's hands-free dictation.
      (no argument)  Fn+Space  - toggles Wispr's hands-free listening mode.
      tap            Fn alone  - ends any running dictation (no toggle-back-on risk).
      enter          Return    - submits the dictated text.

    Requires Accessibility permission for the terminal/app running this binary
    (System Settings > Privacy & Security > Accessibility).
    """)
    exit(0)
}
let src = CGEventSource(stateID: .hidSystemState)
func post(_ e: CGEvent?) { e?.post(tap: .cghidEventTap); usleep(40_000) }
func key(_ code: CGKeyCode, _ down: Bool, _ flags: CGEventFlags) -> CGEvent? {
    let e = CGEvent(keyboardEventSource: src, virtualKey: code, keyDown: down); e?.flags = flags; return e
}
let mode = args.first ?? ""
if mode == "enter" { post(key(36, true, [])); post(key(36, false, [])); exit(0) }
let fnOnly = mode == "tap"
post(key(63, true, .maskSecondaryFn))
if !fnOnly { post(key(49, true, .maskSecondaryFn)); post(key(49, false, .maskSecondaryFn)) }
post(key(63, false, []))
print(AXIsProcessTrusted() ? "accessibility: trusted" : "accessibility: NOT trusted")
