//
//  KidQuestSubmissionView.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI
import UIKit

struct KidQuestSubmissionView: View {
    let quest: FamilyQuest
    let hero: HeroProfile
    let familyName: String
    let isSubmitting: Bool
    let onSubmit: (Data) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var proofImageData: Data?
    @State private var sourceType: UIImagePickerController.SourceType?
    @State private var isShowingSourceDialog = false
    @State private var isShowingSuccess = false
    @State private var expandedProof: ExpandedProof?
    @State private var permissionAlert: QuestMediaPermissionAlert?
    private let previewHeight: CGFloat = 280

    var body: some View {
        ZStack {
            ChoreQuestColors.background
                .ignoresSafeArea()

            QuestBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    questSummaryCard
                    captureSection
                    submitButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }

            if isShowingSuccess {
                successOverlay
            }
        }
        .navigationTitle("Quest Proof")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                QuestProfileAvatar(
                    imageBase64: hero.imageBase64,
                    fallbackIconName: hero.avatarIconName,
                    fallbackColorHex: hero.avatarColorHex,
                    size: 34,
                    borderColor: ChoreQuestColors.primaryFixed
                )
            }
        }
        .fullScreenCover(item: $sourceType) { source in
            CameraLibraryImagePicker(sourceType: source) { data in
                proofImageData = data
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(item: $expandedProof) { proof in
            ExpandedProofImageView(proof: proof)
        }
        .alert(item: $permissionAlert) { alert in
            if alert.opensSettings {
                return Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    primaryButton: .default(Text("Open Settings")) {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        openURL(url)
                    },
                    secondaryButton: .cancel()
                )
            } else {
                return Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private var questSummaryCard: some View {
        ParentSurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 14) {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(ChoreQuestColors.primaryFixed)
                        .frame(width: 72, height: 72)
                        .overlay {
                            Image(systemName: quest.category.iconName)
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(ChoreQuestColors.primary)
                        }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(quest.title)
                            .font(.custom("Quicksand", size: 30).weight(.bold))
                            .foregroundStyle(ChoreQuestColors.onSurface)

                        Text(quest.details)
                            .font(.custom("Quicksand", size: 15).weight(.medium))
                            .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                    }

                    Spacer(minLength: 8)
                }

                HStack(spacing: 10) {
                    Text("\(quest.xpValue) XP")
                        .font(.custom("Quicksand", size: 13).weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(ChoreQuestColors.secondary)
                        .foregroundStyle(ChoreQuestColors.secondaryText)
                        .clipShape(Capsule())

                    Text(familyName)
                        .font(.custom("Quicksand", size: 13).weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(ChoreQuestColors.surfaceContainerLow)
                        .foregroundStyle(ChoreQuestColors.primary)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var captureSection: some View {
        ParentSurfaceCard {
            VStack(spacing: 20) {
                VStack(spacing: 7) {
                    Label("Capture Proof", systemImage: "camera.fill")
                        .font(.custom("Quicksand", size: 26).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.onSurface)

                    Text("Show your commander that the quest is complete.")
                        .font(.custom("Quicksand", size: 14).weight(.medium))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }

                ZStack(alignment: .topTrailing) {
                    Button {
                        isShowingSourceDialog = true
                    } label: {
                        proofPreview
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog(
                        proofImageData == nil ? "Add Proof" : "Replace Proof",
                        isPresented: $isShowingSourceDialog,
                        titleVisibility: .visible
                    ) {
                        Button("Choose from Photo Library", systemImage: "photo.on.rectangle") {
                            Task { await requestPickerAccess(for: .photoLibrary) }
                        }

                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button("Take a Photo", systemImage: "camera.fill") {
                                Task { await requestPickerAccess(for: .camera) }
                            }
                        }

                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Choose how you want to add your quest photo.")
                    }

                    if let proofImageData {
                        HStack {
                            Button {
                                expandedProof = ExpandedProof(imageData: proofImageData)
                            } label: {
                                Image(systemName: "rectangle.expand.diagonal")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Color.black.opacity(0.76))
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.16), radius: 8, y: 4)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Expand proof photo")

                            Spacer()

                            Button {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    self.proofImageData = nil
                                }
                            } label: {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 40, height: 40)
                                    .background(ChoreQuestColors.error)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.16), radius: 8, y: 4)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Remove proof photo")
                        }
                        .padding(14)
                    }
                }
            }
        }
    }

    private var submitButton: some View {
        Button {
            Task {
                guard let proofImageData else { return }
                let didSubmit = await onSubmit(proofImageData)
                guard didSubmit else { return }

                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    isShowingSuccess = true
                }

                try? await Task.sleep(nanoseconds: 1_200_000_000)
                guard !Task.isCancelled else { return }
                dismiss()
            }
        } label: {
            HStack(spacing: 10) {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                }

                Text(isSubmitting ? "Sending to Commander..." : "Submit to Commander")
                    .font(.custom("Quicksand", size: 22).weight(.bold))

                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 24, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(
                LinearGradient(
                    colors: [ChoreQuestColors.primary, ChoreQuestColors.primaryContainer],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: ChoreQuestColors.primary.opacity(0.18), radius: 22, y: 10)
        }
        .buttonStyle(.plain)
        .disabled(proofImageData == nil || isSubmitting)
        .opacity(proofImageData == nil ? 0.6 : 1)
    }

    private var proofPreview: some View {
        GeometryReader { geometry in
            ZStack {
                if let proofImageData, let image = UIImage(data: proofImageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()

                    LinearGradient(
                        colors: [.clear, .black.opacity(0.5)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)

                    VStack(spacing: 0) {
                        Spacer(minLength: 0)

                        HStack(spacing: 9) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(ChoreQuestColors.tertiaryFixed)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Proof ready!")
                                    .font(.custom("Quicksand", size: 17).weight(.bold))

                                Text("Tap the photo to replace it")
                                    .font(.custom("Quicksand", size: 12).weight(.semibold))
                                    .opacity(0.82)
                                    .lineLimit(2)
                            }

                            Spacer(minLength: 8)

                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .padding([.horizontal, .bottom], 12)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    LinearGradient(
                        colors: [ChoreQuestColors.primaryFixed.opacity(0.72), ChoreQuestColors.skyContainer.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)

                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(ChoreQuestColors.primary.opacity(0.12))
                                .frame(width: 104, height: 104)

                            Circle()
                                .fill(ChoreQuestColors.primary)
                                .frame(width: 76, height: 76)

                            Image(systemName: "camera.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        VStack(spacing: 6) {
                            Text("Add a victory photo")
                                .font(.custom("Quicksand", size: 21).weight(.bold))
                                .foregroundStyle(ChoreQuestColors.onSurface)

                            Text("Tap here to use the camera or photo library")
                                .font(.custom("Quicksand", size: 13).weight(.semibold))
                                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                                .multilineTextAlignment(.center)
                        }

                        Label("Choose Photo", systemImage: "plus.circle.fill")
                            .font(.custom("Quicksand", size: 13).weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(ChoreQuestColors.primary)
                            .clipShape(Capsule())
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .padding(.horizontal, 20)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .frame(height: previewHeight)
        .background(ChoreQuestColors.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    proofImageData == nil ? ChoreQuestColors.primary.opacity(0.36) : Color.white.opacity(0.38),
                    style: StrokeStyle(lineWidth: 2, dash: proofImageData == nil ? [9, 7] : [])
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .accessibilityLabel(proofImageData == nil ? "Add proof photo" : "Replace proof photo")
    }

    private var successOverlay: some View {
        Color.black.opacity(0.18)
            .ignoresSafeArea()
            .overlay {
                ParentSurfaceCard {
                    VStack(spacing: 14) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(ChoreQuestColors.tertiary)

                        Text("Quest Logged!")
                            .font(.custom("Quicksand", size: 28).weight(.bold))
                            .foregroundStyle(ChoreQuestColors.onSurface)

                        Text("Your proof has been sent to HQ. Victory is yours!")
                            .font(.custom("Quicksand", size: 15).weight(.medium))
                            .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: 320)
                }
                .padding(.horizontal, 28)
            }
    }

    @MainActor
    private func requestPickerAccess(for sourceType: UIImagePickerController.SourceType) async {
        switch await QuestMediaPermissionService.requestAccess(for: sourceType) {
        case .granted:
            self.sourceType = sourceType
        case .showAlert(let alert):
            permissionAlert = alert
        }
    }
}

private struct ExpandedProof: Identifiable {
    let id = UUID()
    let imageData: Data
}

private struct ExpandedProofImageView: View {
    let proof: ExpandedProof
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if let image = UIImage(data: proof.imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 60)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.18))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(18)
            .accessibilityLabel("Close expanded proof photo")
        }
        .statusBarHidden()
    }
}
