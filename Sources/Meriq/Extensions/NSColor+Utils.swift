//
//  File.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import AppKit
import Foundation

extension NSColor {
    convenience init?(hexString: String) {
        let cleaned = hexString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        guard cleaned.count == 6 || cleaned.count == 8 else {
            return nil
        }

        var value: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&value) else {
            return nil
        }

        let red: UInt64
        let green: UInt64
        let blue: UInt64
        let alpha: UInt64

        if cleaned.count == 8 {
            red = (value & 0xFF00_0000) >> 24
            green = (value & 0x00FF_0000) >> 16
            blue = (value & 0x0000_FF00) >> 8
            alpha = value & 0x0000_00FF
        } else {
            red = (value & 0xFF00_00) >> 16
            green = (value & 0x00FF_00) >> 8
            blue = value & 0x0000_FF
            alpha = 0xFF
        }

        self.init(
            red: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: CGFloat(alpha) / 255
        )
    }

    var hexRGBString: String {
        let rgb = usingColorSpace(.deviceRGB) ?? self
        let red = Int(round(rgb.redComponent * 255))
        let green = Int(round(rgb.greenComponent * 255))
        let blue = Int(round(rgb.blueComponent * 255))
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
