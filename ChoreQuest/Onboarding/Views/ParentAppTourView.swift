//
//  ParentAppTourView.swift
//  ChoreQuest
//

import SwiftUI

struct ParentAppTourView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("appAnimationsEnabled") private var animationsEnabled = true

    let dismissWhenFinished: Bool
    let onFinish: () async -> Bool

    init(
        dismissWhenFinished: Bool = true,
        onFinish: @escaping () async -> Bool
    ) {
        self.dismissWhenFinished = dismissWhenFinished
        self.onFinish = onFinish
    }

    @State private var selectedPage = 0
    @State private var isFinishing = false
    @State private var errorMessage: String?
    @State private var isFloating = false
    @State private var orbitRotation = 0.0
    @State private var decorationsAreVisible = false
    @State private var decorationsArePulsing = false
    @State private var pageBurstScale: CGFloat = 1

    private let pages = ParentTourPage.pages

    var body: some View {
        ZStack {
            ChoreQuestColors.background
                .ignoresSafeArea()
            QuestBackground()

            VStack(spacing: 16) {
                topBar
                progress

                TabView(selection: $selectedPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        tourPage(page, index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                controls
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .interactiveDismissDisabled()
        .onAppear {
            startPlayfulAnimations()
        }
        .onChange(of: animationsEnabled) { _, _ in
            startPlayfulAnimations()
        }
        .onChange(of: reduceMotion) { _, _ in
            startPlayfulAnimations()
        }
        .onChange(of: selectedPage) { _, _ in
            replayPageBurst()
        }
        .alert("Tour Progress", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("PARENT GUIDE")
                    .font(.custom("Quicksand", size: 11).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.primary)
                    .tracking(1)

                Text("Welcome, Commander")
                    .font(.custom("Quicksand", size: 19).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)
                    .lineLimit(1)
            }

            Spacer()

            Button("Skip") {
                finishTour()
            }
            .font(.custom("Quicksand", size: 14).weight(.bold))
            .foregroundStyle(ChoreQuestColors.primary)
            .disabled(isFinishing)
        }
    }

    private var progress: some View {
        HStack(spacing: 7) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index <= selectedPage ? ChoreQuestColors.primary : ChoreQuestColors.surfaceContainerHigh)
                    .frame(maxWidth: .infinity)
                    .frame(height: 6)
                    .animation(.easeOut(duration: 0.2), value: selectedPage)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(selectedPage + 1) of \(pages.count)")
    }

    private func tourPage(_ page: ParentTourPage, index: Int) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(page.accent.opacity(0.18))
                        .frame(width: 190, height: 190)
                        .scaleEffect(motionEnabled ? (isFloating ? 1.18 : 0.9) : 1)

                    Circle()
                        .stroke(page.accent.opacity(0.28), style: StrokeStyle(lineWidth: 3, dash: [7, 9]))
                        .frame(width: 166, height: 166)
                        .rotationEffect(.degrees(selectedPage == index && motionEnabled ? orbitRotation : 0))

                    ForEach(TourDecoration.all) { decoration in
                        Image(systemName: decoration.symbol)
                            .font(.system(size: decoration.size, weight: .bold))
                            .foregroundStyle(decoration.color(page.accent))
                            .offset(
                                x: decoration.x,
                                y: decoration.y + (motionEnabled && isFloating ? decoration.floatOffset : 0)
                            )
                            .scaleEffect(decorationScale(for: index))
                            .opacity(decorationOpacity(for: index))
                            .rotationEffect(.degrees(
                                motionEnabled
                                    ? (isFloating ? decoration.rotation : -decoration.rotation)
                                    : 0
                            ))
                            .symbolEffect(.bounce, value: selectedPage)
                            .animation(
                                motionEnabled
                                    ? .spring(response: 0.46, dampingFraction: 0.56).delay(decoration.delay)
                                    : nil,
                                value: selectedPage
                            )
                    }

                    if page.usesAppLogo {
                        Image("ChoreQuestLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 132, height: 132)
                            .rotationEffect(.degrees(motionEnabled ? (isFloating ? 6 : -6) : 0))
                            .scaleEffect(motionEnabled ? (isFloating ? 1.1 : 0.92) : 1)
                            .offset(y: motionEnabled ? (isFloating ? -16 : 12) : 0)
                    } else {
                        Image(systemName: page.icon)
                            .font(.system(size: 70, weight: .bold))
                            .foregroundStyle(page.accent)
                            .symbolEffect(.bounce, value: selectedPage == index)
                            .rotationEffect(.degrees(motionEnabled ? (isFloating ? 6 : -6) : 0))
                            .scaleEffect(motionEnabled ? (isFloating ? 1.12 : 0.9) : 1)
                            .offset(y: motionEnabled ? (isFloating ? -16 : 12) : 0)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .scaleEffect(selectedPage == index ? pageBurstScale : 0.86)
                .padding(.top, 8)

                VStack(spacing: 10) {
                    Text(page.eyebrow)
                        .font(.custom("Quicksand", size: 12).weight(.bold))
                        .foregroundStyle(page.accent)
                        .tracking(0.8)

                    Text(page.title)
                        .font(.custom("Quicksand", size: 30).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.onSurface)
                        .multilineTextAlignment(.center)

                    Text(page.message)
                        .font(.custom("Quicksand", size: 16).weight(.medium))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .scaleEffect(selectedPage == index ? 1 : 0.96)
                .opacity(selectedPage == index ? 1 : 0.55)
                .animation(.spring(response: 0.4, dampingFraction: 0.82), value: selectedPage)

                VStack(spacing: 10) {
                    ForEach(page.tips, id: \.self) { tip in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(page.accent)

                            Text(tip)
                                .font(.custom("Quicksand", size: 14).weight(.semibold))
                                .foregroundStyle(ChoreQuestColors.onSurface)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(14)
                        .background(ChoreQuestColors.surfaceContainerLowest)
                        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                        .scaleEffect(selectedPage == index ? 1 : 0.94)
                        .opacity(selectedPage == index ? 1 : 0.45)
                        .animation(
                            .spring(response: 0.42, dampingFraction: 0.78).delay(0.06),
                            value: selectedPage
                        )
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 12)
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            if selectedPage > 0 {
                Button {
                    move(to: selectedPage - 1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(ChoreQuestColors.primary)
                        .frame(width: 54, height: 54)
                        .background(ChoreQuestColors.surfaceContainerLowest, in: Circle())
                        .overlay(Circle().stroke(ChoreQuestColors.outlineVariant, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Previous tour page")
            }

            Button {
                if selectedPage == pages.count - 1 {
                    finishTour()
                } else {
                    move(to: selectedPage + 1)
                }
            } label: {
                HStack(spacing: 9) {
                    if isFinishing {
                        ProgressView()
                            .tint(.white)
                    }

                    Text(selectedPage == pages.count - 1 ? "Build My Squad" : "Next")
                    Image(systemName: selectedPage == pages.count - 1 ? "sparkles" : "arrow.right")
                        .symbolEffect(.bounce, value: selectedPage)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(QuestPrimaryButtonStyle())
            .disabled(isFinishing)
        }
    }

    private func move(to page: Int) {
        withAnimation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.84)) {
            selectedPage = page
        }
    }

    private var motionEnabled: Bool {
        animationsEnabled && !reduceMotion
    }

    private func decorationScale(for index: Int) -> CGFloat {
        guard decorationsAreVisible, selectedPage == index else { return 0.2 }
        guard motionEnabled else { return 1 }
        return decorationsArePulsing ? 1.22 : 0.78
    }

    private func decorationOpacity(for index: Int) -> Double {
        guard decorationsAreVisible, selectedPage == index else { return 0 }
        guard motionEnabled else { return 1 }
        return decorationsArePulsing ? 1 : 0.58
    }

    private func startPlayfulAnimations() {
        guard motionEnabled else {
            isFloating = false
            orbitRotation = 0
            decorationsAreVisible = true
            decorationsArePulsing = false
            pageBurstScale = 1
            return
        }

        isFloating = false
        orbitRotation = 0
        decorationsAreVisible = false
        decorationsArePulsing = false
        pageBurstScale = 1

        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            isFloating = true
        }
        withAnimation(.linear(duration: 4.8).repeatForever(autoreverses: false)) {
            orbitRotation = 360
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.58).delay(0.12)) {
            decorationsAreVisible = true
        }
        withAnimation(.easeInOut(duration: 0.72).repeatForever(autoreverses: true)) {
            decorationsArePulsing = true
        }
    }

    private func replayPageBurst() {
        guard motionEnabled else {
            pageBurstScale = 1
            return
        }

        withAnimation(.none) {
            pageBurstScale = 0.7
        }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.48).delay(0.04)) {
            pageBurstScale = 1
        }
    }

    private func finishTour() {
        guard !isFinishing else { return }
        isFinishing = true

        Task {
            let didFinish = await onFinish()
            isFinishing = false
            if didFinish, dismissWhenFinished {
                dismiss()
            } else {
                if !didFinish {
                    errorMessage = "We couldn't save that the tour was completed. Please try again."
                }
            }
        }
    }
}

private struct TourDecoration: Identifiable {
    let id: Int
    let symbol: String
    let size: CGFloat
    let x: CGFloat
    let y: CGFloat
    let floatOffset: CGFloat
    let rotation: Double
    let delay: Double
    let usesAccent: Bool

    func color(_ accent: Color) -> Color {
        usesAccent ? accent : ChoreQuestColors.secondary
    }

    static let all: [TourDecoration] = [
        TourDecoration(id: 0, symbol: "star.fill", size: 22, x: -92, y: -60, floatOffset: -17, rotation: 34, delay: 0.02, usesAccent: false),
        TourDecoration(id: 1, symbol: "sparkle", size: 26, x: 91, y: -48, floatOffset: 18, rotation: -38, delay: 0.1, usesAccent: true),
        TourDecoration(id: 2, symbol: "bolt.fill", size: 18, x: -94, y: 64, floatOffset: 15, rotation: -30, delay: 0.18, usesAccent: true),
        TourDecoration(id: 3, symbol: "circle.fill", size: 12, x: 88, y: 70, floatOffset: -15, rotation: 0, delay: 0.26, usesAccent: false)
    ]
}

private struct ParentTourPage: Identifiable {
    let id: String
    let eyebrow: String
    let title: String
    let message: String
    let icon: String
    let accent: Color
    let tips: [String]
    var usesAppLogo = false

    static let pages: [ParentTourPage] = [
        ParentTourPage(
            id: "welcome",
            eyebrow: "BEFORE YOU BUILD YOUR SQUAD",
            title: "Learn the ChoreQuest language",
            message: "ChoreQuest turns family responsibilities into an adventure. Here are the names and ideas you'll see while creating your family.",
            icon: "shield.fill",
            accent: ChoreQuestColors.primary,
            tips: [
                "This quick guide comes before family profile creation.",
                "You'll know exactly what each setup choice means."
            ],
            usesAppLogo: true
        ),
        ParentTourPage(
            id: "roles",
            eyebrow: "WHO'S WHO",
            title: "Commander and Heroes",
            message: "The Commander is the parent or guardian. Heroes are the kids who receive quests, submit proof, earn XP, and choose rewards.",
            icon: "crown.fill",
            accent: ChoreQuestColors.secondaryText,
            tips: [
                "Commander controls stay in protected Parent mode.",
                "Each Hero gets a separate profile and progress history."
            ]
        ),
        ParentTourPage(
            id: "identity",
            eyebrow: "YOUR FAMILY IDENTITY",
            title: "Squad and Crest",
            message: "Your Squad is the whole family team. Its name appears around the app, while the Crest is the symbol that represents your team.",
            icon: "shield.fill",
            accent: ChoreQuestColors.primaryContainer,
            tips: [
                "Choose a Squad name your family recognizes.",
                "The Crest is decorative and can be changed later."
            ]
        ),
        ParentTourPage(
            id: "tokens",
            eyebrow: "HERO IDENTITY",
            title: "Tokens and profile photos",
            message: "A Token is a playful animal avatar that helps identify a Hero throughout the app. A real profile photo is optional and can be used instead.",
            icon: "pawprint.fill",
            accent: ChoreQuestColors.pink,
            tips: [
                "Every Hero always has an animal Token fallback.",
                "Profile photos stay inside the signed-in family experience."
            ]
        ),
        ParentTourPage(
            id: "quests",
            eyebrow: "EVERYDAY ADVENTURES",
            title: "Quests and XP",
            message: "A Quest is a responsibility created by the Commander and assigned to one or more Heroes. XP is the progress earned when that Quest is approved.",
            icon: "checklist.checked",
            accent: ChoreQuestColors.sky,
            tips: [
                "Clear instructions help Heroes know what success looks like.",
                "XP powers personal rewards and shared family progress."
            ]
        ),
        ParentTourPage(
            id: "proof",
            eyebrow: "CHECK, CHEER, COACH",
            title: "Proof and Approvals",
            message: "Proof is a photo a Hero can submit after completing a Quest. It appears in Approvals, where the Commander accepts it or leaves a kind note about what to fix.",
            icon: "checkmark.seal.fill",
            accent: ChoreQuestColors.tertiaryContainer,
            tips: [
                "Approving proof awards the Quest XP.",
                "Rejected proof can be corrected and submitted again."
            ]
        ),
        ParentTourPage(
            id: "rewards",
            eyebrow: "CELEBRATE TOGETHER",
            title: "Rewards and family goals",
            message: "The Reward Shop holds rewards Heroes can claim with XP. A Family Goal is a shared reward that everyone can help unlock.",
            icon: "gift.fill",
            accent: ChoreQuestColors.coral,
            tips: [
                "Heroes decide how much of their earned XP to contribute.",
                "Switch Device Mode when handing the app from Commander to Hero."
            ]
        )
    ]
}
