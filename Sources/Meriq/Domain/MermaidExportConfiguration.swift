//
//  MermaidExportConfiguration.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//

import Foundation

struct MermaidExportConfiguration: Equatable {
    var variant: MermaidExportVariant = .svg
    var scale: Double = 2.0
}
