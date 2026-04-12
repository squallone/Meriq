//
//  PreviewToolMode.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import Foundation

enum PreviewToolMode: Equatable {
    case none
    case zoomIn
    case zoomOut

    var isActive: Bool {
        self != .none
    }

    var symbolName: String {
        switch self {
        case .none:
            "cursorarrow"
        case .zoomIn:
            "plus.magnifyingglass"
        case .zoomOut:
            "minus.magnifyingglass"
        }
    }

    var title: String {
        switch self {
        case .none:
            "Preview Tool"
        case .zoomIn:
            "Zoom In"
        case .zoomOut:
            "Zoom Out"
        }
    }

    var instruction: String {
        switch self {
        case .none:
            ""
        case .zoomIn:
            "Click the diagram to zoom in."
        case .zoomOut:
            "Click the diagram to zoom out."
        }
    }
}
