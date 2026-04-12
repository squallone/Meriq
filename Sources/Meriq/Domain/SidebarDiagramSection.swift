//
//  SidebarDiagramSection.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//

import Foundation

struct SidebarDiagramSection: Identifiable, Equatable {
    let id: String
    let title: String
    let symbolName: String
    let tintHex: String?
    let diagrams: [Diagram]
}
