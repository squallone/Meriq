//
//  PreviewShortcutMonitor.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import AppKit
import SwiftUI

struct PreviewShortcutMonitor: NSViewRepresentable {
    @EnvironmentObject private var editorStore: EditorStore

    func makeCoordinator() -> Coordinator {
        Coordinator(editorStore: editorStore)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.installIfNeeded()
        return view
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.teardown()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.editorStore = editorStore
        context.coordinator.installIfNeeded()
    }

    @MainActor
    final class Coordinator {
        weak var editorStore: EditorStore?
        private var keyMonitor: Any?
        private var isZKeyDown = false
        private var isOptionKeyDown = false

        init(editorStore: EditorStore) {
            self.editorStore = editorStore
        }

        func installIfNeeded() {
            guard keyMonitor == nil else { return }

            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { [weak self] event in
                guard let self else { return event }
                guard self.shouldHandle(event: event) else { return event }
                return self.handle(event: event)
            }
        }

        func teardown() {
            if let keyMonitor {
                NSEvent.removeMonitor(keyMonitor)
                self.keyMonitor = nil
            }
            isZKeyDown = false
            isOptionKeyDown = false
        }

        private func shouldHandle(event: NSEvent) -> Bool {
            guard event.type == .keyDown || event.type == .keyUp || event.type == .flagsChanged else { return false }

            let isTextInputActive = MainActor.assumeIsolated {
                if let firstResponder = NSApp.keyWindow?.firstResponder, firstResponder is NSTextView {
                    return true
                }
                return false
            }

            if isTextInputActive {
                return false
            }

            return true
        }

        private func handle(event: NSEvent) -> NSEvent? {
            switch event.type {
            case .flagsChanged:
                let wasOptionDown = isOptionKeyDown
                isOptionKeyDown = event.modifierFlags.contains(.option)

                guard wasOptionDown != isOptionKeyDown, isZKeyDown else {
                    return event
                }

                Task { @MainActor [weak self] in
                    self?.editorStore?.updateKeyboardZoomSession(optionPressed: self?.isOptionKeyDown == true)
                }
                return nil

            case .keyDown:
                let characters = event.charactersIgnoringModifiers?.lowercased() ?? ""

                if characters == "\u{1b}" {
                    isZKeyDown = false
                    Task { @MainActor [weak self] in
                        self?.editorStore?.cancelPreviewTool()
                    }
                    return nil
                }

                guard characters == "z" else { return event }
                guard !event.isARepeat else { return nil }

                isZKeyDown = true
                isOptionKeyDown = event.modifierFlags.contains(.option)
                Task { @MainActor [weak self] in
                    self?.editorStore?.beginKeyboardZoomSession(optionPressed: self?.isOptionKeyDown == true)
                }
                return nil

            case .keyUp:
                let characters = event.charactersIgnoringModifiers?.lowercased() ?? ""
                guard characters == "z" else { return event }

                isZKeyDown = false
                Task { @MainActor [weak self] in
                    self?.editorStore?.endKeyboardZoomSession()
                }
                return nil

            default:
                return event
            }
        }
    }
}
