//
//  PlayfulLaunchView.swift
//  ChoreQuest
//

import SwiftUI

struct PlayfulLaunchView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("appAnimationsEnabled") private var animationsEnabled = true

    let onFinished: () -> Void

    @State private var hasStarted = false
    @State private var decorationsAreVisible = false
    @State private var titleIsVisible = false
    @State private var logoScale: CGFloat = 1
    @State private var logoRotation: Double = 0
    @State private var logoOffset: CGFloat = 0
    @State private var orbitRotation: Double = 0
    @State private var contentOpacity = 1.0

    var body: some View {
        ZStack {
            ChoreQuestColors.background
                .ignoresSafeArea()

            launchBackdrop
            logo
            title
        }
        .opacity(contentOpacity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ChoreQuest is starting")
        .task {
            await playAnimation()
        }
    }

    private var launchBackdrop: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .fill(ChoreQuestColors.primaryContainer.opacity(0.16))
                    .frame(width: 280, height: 280)
                    .blur(radius: 24)
                    .position(x: 16, y: 90)

                Circle()
                    .fill(ChoreQuestColors.secondary.opacity(0.22))
                    .frame(width: 330, height: 330)
                    .blur(radius: 30)
                    .position(x: proxy.size.width - 12, y: proxy.size.height - 55)

                ForEach(LaunchDecoration.all) { decoration in
                    Image(systemName: decoration.symbol)
                        .font(.system(size: decoration.size, weight: .bold))
                        .foregroundStyle(decoration.color)
                        .scaleEffect(decorationsAreVisible ? 1 : 0.2)
                        .opacity(decorationsAreVisible ? 1 : 0)
                        .rotationEffect(.degrees(
                            decoration.rotation + (decorationsAreVisible ? decoration.spin : 0)
                        ))
                        .position(
                            x: proxy.size.width * decoration.x,
                            y: proxy.size.height * decoration.y
                        )
                        .animation(
                            .spring(response: 0.52, dampingFraction: 0.58)
                                .delay(decoration.delay),
                            value: decorationsAreVisible
                        )
                }
            }
        }
        .accessibilityHidden(true)
    }

    private var logo: some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            ChoreQuestColors.secondary,
                            ChoreQuestColors.pink,
                            ChoreQuestColors.sky,
                            ChoreQuestColors.secondary
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [3, 13])
                )
                .frame(width: 232, height: 232)
                .opacity(decorationsAreVisible ? 0.8 : 0)
                .rotationEffect(.degrees(orbitRotation))

            Circle()
                .fill(ChoreQuestColors.secondary.opacity(decorationsAreVisible ? 0.26 : 0))
                .frame(width: 212, height: 212)
                .blur(radius: 18)

            Image("ChoreQuestLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .shadow(
                    color: ChoreQuestColors.primary.opacity(decorationsAreVisible ? 0.24 : 0),
                    radius: 22,
                    y: 12
                )
        }
        .scaleEffect(logoScale)
        .rotationEffect(.degrees(logoRotation))
        .offset(y: logoOffset)
        .accessibilityHidden(true)
    }

    private var title: some View {
        VStack(spacing: 5) {
            Text("ChoreQuest")
                .font(.custom("Quicksand", size: 30).weight(.bold))
                .foregroundStyle(ChoreQuestColors.primary)

            Text("Little tasks. Big adventures.")
                .font(.custom("Quicksand", size: 15).weight(.semibold))
                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
        }
        .offset(y: 160)
        .scaleEffect(titleIsVisible ? 1 : 0.82)
        .opacity(titleIsVisible ? 1 : 0)
        .accessibilityHidden(true)
    }

    @MainActor
    private func playAnimation() async {
        guard !hasStarted else { return }
        hasStarted = true

        guard animationsEnabled, !reduceMotion else {
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation(.easeOut(duration: 0.2)) {
                contentOpacity = 0
            }
            try? await Task.sleep(for: .milliseconds(200))
            onFinished()
            return
        }

        try? await Task.sleep(for: .milliseconds(100))

        decorationsAreVisible = true
        withAnimation(.spring(response: 0.4, dampingFraction: 0.52)) {
            logoScale = 1.1
            logoRotation = 3
            logoOffset = -10
            titleIsVisible = true
        }
        withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
            orbitRotation = 360
        }

        try? await Task.sleep(for: .milliseconds(480))

        withAnimation(.spring(response: 0.44, dampingFraction: 0.62)) {
            logoScale = 1
            logoRotation = -2
            logoOffset = 0
        }

        try? await Task.sleep(for: .milliseconds(760))

        withAnimation(.easeInOut(duration: 0.28)) {
            contentOpacity = 0
            logoScale = 1.12
        }

        try? await Task.sleep(for: .milliseconds(280))
        onFinished()
    }
}

private struct LaunchDecoration: Identifiable {
    let id: Int
    let symbol: String
    let color: Color
    let size: CGFloat
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let spin: Double
    let delay: Double

    static let all: [LaunchDecoration] = [
        LaunchDecoration(id: 0, symbol: "star.fill", color: ChoreQuestColors.secondary, size: 24, x: 0.18, y: 0.22, rotation: -12, spin: 24, delay: 0.02),
        LaunchDecoration(id: 1, symbol: "sparkle", color: ChoreQuestColors.pink, size: 28, x: 0.82, y: 0.25, rotation: 8, spin: -30, delay: 0.09),
        LaunchDecoration(id: 2, symbol: "bolt.fill", color: ChoreQuestColors.sky, size: 22, x: 0.13, y: 0.69, rotation: -16, spin: 18, delay: 0.16),
        LaunchDecoration(id: 3, symbol: "star.fill", color: ChoreQuestColors.primaryContainer, size: 17, x: 0.87, y: 0.66, rotation: 14, spin: -22, delay: 0.23),
        LaunchDecoration(id: 4, symbol: "circle.fill", color: ChoreQuestColors.secondary.opacity(0.8), size: 12, x: 0.28, y: 0.81, rotation: 0, spin: 0, delay: 0.3),
        LaunchDecoration(id: 5, symbol: "sparkles", color: ChoreQuestColors.primary, size: 20, x: 0.72, y: 0.79, rotation: -6, spin: 20, delay: 0.36)
    ]
}
