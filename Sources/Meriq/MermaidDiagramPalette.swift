//
//  MermaidDiagramPalette.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import Foundation

struct MermaidDiagramPalette: Codable, Equatable {
    let background: String
    let primaryColor: String
    let primaryTextColor: String
    let primaryBorderColor: String
    let lineColor: String
    let secondaryColor: String
    let tertiaryColor: String
    let fontFamily: String
}
