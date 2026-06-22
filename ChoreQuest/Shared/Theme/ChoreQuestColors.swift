//
//  ChoreQuestColors.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI

enum ChoreQuestColors {
    static let background = Color(hex: 0xf7f5ff)
    static let surfaceContainer = Color(hex: 0xe9e2ff)
    static let surfaceContainerLow = Color(hex: 0xf1edff)
    static let surfaceContainerHigh = Color(hex: 0xded5ff)
    static let surfaceContainerHighest = Color(hex: 0xd2c6ff)
    static let surfaceContainerLowest = Color(hex: 0xffffff)
    static let onSurface = Color(hex: 0x0b1c30)
    static let onSurfaceVariant = Color(hex: 0x4a4455)
    static let primary = Color(hex: 0x6c35e8)
    static let primaryContainer = Color(hex: 0x8557f2)
    static let primaryFixed = Color(hex: 0xeaddff)
    static let primaryShadow = Color(hex: 0x4c0bb3)
    static let secondary = Color(hex: 0xffcc3d)
    static let secondaryText = Color(hex: 0x6f5100)
    static let tertiary = Color(hex: 0x005b3d)
    static let tertiaryContainer = Color(hex: 0x007650)
    static let tertiaryFixed = Color(hex: 0x6ffbbe)
    static let tertiaryText = Color(hex: 0x002113)
    static let outline = Color(hex: 0x7b7487)
    static let outlineVariant = Color(hex: 0xccc3d8)
    static let error = Color(hex: 0xba1a1a)
    static let errorText = Color(hex: 0x93000a)
    static let errorContainer = Color(hex: 0xffdad6)
    static let sky = Color(hex: 0x42c9f5)
    static let skyContainer = Color(hex: 0xd9f6ff)
    static let coral = Color(hex: 0xff6b6b)
    static let coralContainer = Color(hex: 0xffe3e3)
    static let pink = Color(hex: 0xf062c0)
    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x6c35e8), Color(hex: 0x9b5cf6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
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
