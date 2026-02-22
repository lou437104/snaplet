import AppKit
import ApplicationServices

enum WindowSnapper {

    static func snapLastActiveAppLeft() {
        NSLog("Snaplet: BUTTON PRESSED")

        // 1) Accessibility check
        guard AXIsProcessTrusted() else {
            NSLog("Snaplet: AX not trusted")
            return
        }

        // 2) Get last non-snaplet PID from your AppState
        guard let pid = AppState.shared.lastNonSnapletPID else {
            NSLog("Snaplet: No lastNonSnapletPID yet")
            return
        }

        NSLog("Snaplet: PID = \(pid)")

        let appElement = AXUIElementCreateApplication(pid)

        // 3) Find a usable window
        guard let window = findBestWindow(for: appElement) else {
            NSLog("Snaplet: FAILED TO GET WINDOW")
            return
        }

        // 4) Pick screen (use the screen where the window currently is, if possible)
        let screen = screenForWindow(window) ?? NSScreen.main
        guard let screen else {
            NSLog("Snaplet: No screen found")
            return
        }

        let vf = screen.visibleFrame

        // 5) Target: left half
        let targetW = vf.width / 2.0
        let targetH = vf.height
        let targetX = vf.minX
        let targetY = vf.minY

        // Convert Cocoa (bottom-left origin) -> AX (top-left origin relative to global screen space)
        // AX expects Y measured from TOP of the screen.
        let screenFrame = screen.frame
        let axX = targetX
        let axY = screenFrame.maxY - (targetY + targetH)

        NSLog("Snaplet: Target cocoa=(\(targetX),\(targetY),\(targetW),\(targetH)) ax=(\(axX),\(axY))")

        // 6) Apply size then position (some apps behave better this way)
        let sizeOk = setAXSize(CGSize(width: targetW, height: targetH), for: window)
        let posOk  = setAXPosition(CGPoint(x: axX, y: axY), for: window)

        NSLog("Snaplet: set size ok=\(sizeOk) pos ok=\(posOk)")
    }

    // MARK: - Window finding (more reliable than only kAXMainWindow)

    private static func findBestWindow(for app: AXUIElement) -> AXUIElement? {
        // Try focused window first
        if let w = copyWindow(app: app, attr: kAXFocusedWindowAttribute) {
            NSLog("Snaplet: got focusedWindow")
            return w
        }

        // Then main window
        if let w = copyWindow(app: app, attr: kAXMainWindowAttribute) {
            NSLog("Snaplet: got mainWindow")
            return w
        }

        // Then first in windows list
        if let windows = copyWindowsList(app: app), let first = windows.first {
            NSLog("Snaplet: got first window from windows list (\(windows.count) total)")
            return first
        }

        return nil
    }

    private static func copyWindow(app: AXUIElement, attr: String) -> AXUIElement? {
        var ref: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(app, attr as CFString, &ref)

        if err != .success {
            NSLog("Snaplet: Copy \(attr) failed: \(err.rawValue)")
            return nil
        }

        guard let win = ref else { return nil }
        return (win as! AXUIElement)
    }
    private static func copyWindowsList(app: AXUIElement) -> [AXUIElement]? {
        var ref: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &ref)

        if err != .success {
            NSLog("Snaplet: Copy windows list failed: \(err.rawValue)")
            return nil
        }

        return (ref as? [AXUIElement])
    }

    // MARK: - Apply AX attributes with logging

    private static func setAXPosition(_ point: CGPoint, for window: AXUIElement) -> Bool {
        var p = point
        guard let value = AXValueCreate(.cgPoint, &p) else {
            NSLog("Snaplet: AXValueCreate(cgPoint) failed")
            return false
        }

        let err = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value)
        if err != .success {
            NSLog("Snaplet: Set position failed: \(err.rawValue)")
            return false
        }
        return true
    }

    private static func setAXSize(_ size: CGSize, for window: AXUIElement) -> Bool {
        var s = size
        guard let value = AXValueCreate(.cgSize, &s) else {
            NSLog("Snaplet: AXValueCreate(cgSize) failed")
            return false
        }

        let err = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value)
        if err != .success {
            NSLog("Snaplet: Set size failed: \(err.rawValue)")
            return false
        }
        return true
    }

    // MARK: - Screen selection

    private static func screenForWindow(_ window: AXUIElement) -> NSScreen? {
        // Try to read window position and decide which screen it’s on
        var ref: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &ref)
        guard err == .success, let ref else { return nil }

        let axVal = (ref as! AXValue)

        var pt = CGPoint.zero
        AXValueGetValue(axVal, .cgPoint, &pt)

        // AX point is in global AX coords (top-left origin),
        // but screen.frame is in Cocoa coords (bottom-left).
        // We’ll just match by x-range (good enough for choosing screen).
        let screens = NSScreen.screens
        return screens.first(where: { $0.frame.minX...$0.frame.maxX ~= pt.x }) ?? NSScreen.main
    }
}
