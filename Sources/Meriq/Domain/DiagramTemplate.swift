//
//  DiagramTemplate.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//

import Foundation

struct DiagramTemplate: Identifiable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String
    let symbolName: String
    let source: String
}
