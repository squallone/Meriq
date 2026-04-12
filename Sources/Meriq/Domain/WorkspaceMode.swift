//
//  WorkspaceMode.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import Foundation

enum WorkspaceMode: String, CaseIterable, Identifiable {
    case editor
    case split
    case preview

    var id: String { rawValue }

    var title: String {
        switch self {
        case .editor:
            "Editor"
        case .split:
            "Split View"
        case .preview:
            "Preview"
        }
    }
}
