//
//  DiagramScope.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import Foundation

enum DiagramScope: Equatable {
    case recents
    case favorites
    case allDiagrams
    case uncategorized
    case category(UUID)
}
