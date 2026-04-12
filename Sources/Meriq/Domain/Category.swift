//
//  Category.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//

import Foundation

struct Category: Identifiable, Equatable {
    let id: UUID
    var name: String
    var iconSystemName: String
    var colorHex: String?
    var sortOrder: Int
    var diagramCount: Int
}
