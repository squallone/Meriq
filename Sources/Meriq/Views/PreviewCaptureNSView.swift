//
//  PreviewCaptureNSView.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import AppKit

@MainActor
final class PreviewCaptureNSView: NSView {
    weak var coordinator: PreviewClickCaptureView.Coordinator?
    var currentMode: PreviewToolMode = .none {
        didSet {
            if oldValue != currentMode {
                if currentMode == .none {
                    PreviewToolCursor.reset()
                }
                needsDisplay = true
            }
        }
    }

    private var clickMonitor: Any?
    private var trackingAreaReference: NSTrackingArea?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        installClickMonitorIfNeeded()
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil {
            teardown()
        }
        super.viewWillMove(toWindow: newWindow)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingAreaReference {
            removeTrackingArea(trackingAreaReference)
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .inVisibleRect, .mouseEnteredAndExited, .cursorUpdate],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        trackingAreaReference = trackingArea
    }

    override func mouseEntered(with event: NSEvent) {
        updateCursor()
    }

    override func mouseExited(with event: NSEvent) {
        PreviewToolCursor.reset()
    }

    override func cursorUpdate(with event: NSEvent) {
        updateCursor()
    }

    private func installClickMonitorIfNeeded() {
        guard clickMonitor == nil else { return }

        clickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            guard let self else { return event }
            guard currentMode.isActive else { return event }

            let boundsInWindow = convert(bounds, to: nil)
            guard boundsInWindow.contains(event.locationInWindow) else { return event }

            coordinator?.onPreviewClick()
            return event
        }
    }

    func teardown() {
        if let clickMonitor {
            NSEvent.removeMonitor(clickMonitor)
            self.clickMonitor = nil
        }
        PreviewToolCursor.reset()
    }

    private func updateCursor() {
        PreviewToolCursor.set(mode: currentMode, active: currentMode.isActive)
    }
}
