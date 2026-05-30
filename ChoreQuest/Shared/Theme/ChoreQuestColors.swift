//
//  ChoreQuestColors.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI

enum ChoreQuestColors {
    static let background = Color(hex: 0xf8f9ff)
    static let surfaceContainer = Color(hex: 0xe5eeff)
    static let surfaceContainerLow = Color(hex: 0xeff4ff)
    static let surfaceContainerHigh = Color(hex: 0xdce9ff)
    static let onSurface = Color(hex: 0x0b1c30)
    static let onSurfaceVariant = Color(hex: 0x4a4455)
    static let primary = Color(hex: 0x630ed4)
    static let primaryContainer = Color(hex: 0x7c3aed)
    static let primaryShadow = Color(hex: 0x4c0bb3)
    static let secondary = Color(hex: 0xffc329)
    static let outline = Color(hex: 0x7b7487)
    static let outlineVariant = Color(hex: 0xccc3d8)
    static let error = Color(hex: 0xba1a1a)
    static let errorText = Color(hex: 0x93000a)
    static let errorContainer = Color(hex: 0xffdad6)
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}
