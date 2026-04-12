//
//  DiagramPreviewZoomState.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//

import Foundation

struct DiagramPreviewZoomState: Equatable {
    static let defaultScale: CGFloat = 1.0
    static let minimumScale: CGFloat = 0.5
    static let maximumScale: CGFloat = 2.0
    static let step: CGFloat = 0.1

    var scale: CGFloat = defaultScale

    var canZoomIn: Bool {
        scale < Self.maximumScale - 0.001
    }

    var canZoomOut: Bool {
        scale > Self.minimumScale + 0.001
    }

    var percentageLabel: String {
        "\(Int((scale * 100).rounded()))%"
    }

    func zoomingIn() -> Self {
        var copy = self
        copy.scale = min(Self.maximumScale, scale + Self.step)
        return copy
    }

    func zoomingOut() -> Self {
        var copy = self
        copy.scale = max(Self.minimumScale, scale - Self.step)
        return copy
    }

    func resetting() -> Self {
        var copy = self
        copy.scale = Self.defaultScale
        return copy
    }
}
