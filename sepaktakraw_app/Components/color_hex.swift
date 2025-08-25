//
//  Color+Hex.swift
//  sepaktakraw_app
//
//  Created by 折田研究室 on 2025/08/16.
//

import SwiftUI

extension Color {
    // Hex文字列からColorを生成
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        if hex.count == 6 {
            r = (int >> 16) & 0xFF
            g = (int >> 8) & 0xFF
            b = int & 0xFF
        } else {
            r = 1; g = 1; b = 1
        }
        self.init(
            .sRGB,
            red: Double(r)/255,
            green: Double(g)/255,
            blue: Double(b)/255,
            opacity: 1
        )
    }

    // ColorからHex文字列を生成
    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format:"#%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
    }
}
