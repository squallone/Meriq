//
//  SidebarSelection.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//

import Foundation
import CoreGraphics

enum SidebarSelection: Hashable {
    case recents
    case favorites
    case templates
    case allDiagrams
    case uncategorized
    case category(UUID)
}
