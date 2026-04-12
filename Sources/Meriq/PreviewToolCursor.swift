//
//  PreviewToolCursor.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import SwiftUI

enum PreviewToolCursor {
    static func set(mode: PreviewToolMode, active: Bool) {
        guard active else {
            reset()
            return
        }

        cursor(for: mode).set()
    }

    static func reset() {
        NSCursor.arrow.set()
    }

    private static func cursor(for mode: PreviewToolMode) -> NSCursor {
        switch mode {
        case .none:
            return .arrow
        case .zoomIn:
            return makeCursor(systemSymbolName: "plus.magnifyingglass")
        case .zoomOut:
            return makeCursor(systemSymbolName: "minus.magnifyingglass")
        }
    }

    private static func makeCursor(systemSymbolName: String) -> NSCursor {
        let size = NSSize(width: 28, height: 28)
        let image = NSImage(size: size, flipped: false) { rect in
            let backgroundPath = NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1))
            NSColor(calibratedWhite: 0.08, alpha: 0.94).setFill()
            backgroundPath.fill()

            NSColor.white.withAlphaComponent(0.12).setStroke()
            backgroundPath.lineWidth = 1
            backgroundPath.stroke()

            let configuration = NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
            let symbol = NSImage(systemSymbolName: systemSymbolName, accessibilityDescription: nil)?
                .withSymbolConfiguration(configuration)
            let symbolRect = NSRect(x: 6, y: 6, width: 16, height: 16)
            symbol?.draw(in: symbolRect)
            return true
        }

        return NSCursor(image: image, hotSpot: NSPoint(x: 14, y: 14))
    }
}
