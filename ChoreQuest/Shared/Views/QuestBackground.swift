//
//  QuestBackground.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI

struct QuestBackground: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(ChoreQuestColors.primaryContainer.opacity(0.12))
                .frame(width: 240, height: 240)
                .blur(radius: 34)
                .offset(x: -150, y: -310)

            Circle()
                .fill(ChoreQuestColors.secondary.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 36)
                .offset(x: 160, y: 320)

            DotPattern()
                .stroke(ChoreQuestColors.surfaceContainerHigh.opacity(0.8), lineWidth: 2)
                .opacity(0.45)
                .ignoresSafeArea()
        }
        .ignoresSafeArea()
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
