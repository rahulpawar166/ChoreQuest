//
//  QuestBackground.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI

struct QuestBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("appAnimationsEnabled") private var animationsEnabled = true
    @State private var isFloating = false

    var body: some View {
        ZStack {
            Circle()
                .fill(ChoreQuestColors.primaryContainer.opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 28)
                .offset(x: isFloating ? -125 : -165, y: isFloating ? -285 : -330)

            Circle()
                .fill(ChoreQuestColors.secondary.opacity(0.24))
                .frame(width: 300, height: 300)
                .blur(radius: 32)
                .offset(x: isFloating ? 135 : 175, y: isFloating ? 290 : 340)

            Circle()
                .fill(ChoreQuestColors.sky.opacity(0.14))
                .frame(width: 190, height: 190)
                .blur(radius: 26)
                .offset(x: isFloating ? 150 : 120, y: isFloating ? -110 : -150)

            DotPattern()
                .stroke(ChoreQuestColors.surfaceContainerHigh.opacity(0.8), lineWidth: 2)
                .opacity(0.55)
                .ignoresSafeArea()

            floatingSymbol("star.fill", color: ChoreQuestColors.secondary, x: 138, y: -250, rotation: isFloating ? 18 : -8)
            floatingSymbol("sparkle", color: ChoreQuestColors.pink, x: -145, y: 80, rotation: isFloating ? -12 : 12)
            floatingSymbol("circle.fill", color: ChoreQuestColors.sky, x: 150, y: 160, rotation: 0)
        }
        .ignoresSafeArea()
        .onAppear {
            guard animationsEnabled, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                isFloating = true
            }
        }
        .onChange(of: animationsEnabled) { _, isEnabled in
            guard isEnabled, !reduceMotion else {
                isFloating = false
                return
            }
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                isFloating = true
            }
        }
    }

    private func floatingSymbol(_ name: String, color: Color, x: CGFloat, y: CGFloat, rotation: Double) -> some View {
        Image(systemName: name)
            .font(.system(size: name == "circle.fill" ? 9 : 18, weight: .bold))
            .foregroundStyle(color.opacity(0.42))
            .rotationEffect(.degrees(rotation))
            .offset(x: x, y: y + (isFloating ? -12 : 12))
            .accessibilityHidden(true)
    }
}

private struct DotPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 40

        for x in stride(from: rect.minX, through: rect.maxX, by: step) {
            for y in stride(from: rect.minY, through: rect.maxY, by: step) {
                path.addEllipse(in: CGRect(x: x, y: y, width: 2, height: 2))
            }
        }

        return path
    }
}
