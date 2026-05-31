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
        .navigationBarTitleDisplayMode(.inline)
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
        .confirmationDialog("Add Proof", isPresented: $isShowingSourceDialog) {
            Button("Choose from Gallery") {
                Task {
                    await requestPickerAccess(for: .photoLibrary)
                }
            }

            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") {
                    Task {
                        await requestPickerAccess(for: .camera)
                    }
                }
            }

            if proofImageData != nil {
                Button("Remove Photo", role: .destructive) {
                    proofImageData = nil
                }
            }
        }
        .sheet(item: $sourceType) { source in
            CameraLibraryImagePicker(sourceType: source) { data in
                proofImageData = data
            }
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
            VStack(alignment: .leading, spacing: 18) {
                Text("Capture Proof")
                    .font(.custom("Quicksand", size: 28).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)

                Text("Show your commander that the quest is done with a clear photo.")
                    .font(.custom("Quicksand", size: 15).weight(.medium))
                    .foregroundStyle(ChoreQuestColors.onSurfaceVariant)

                Button {
                    isShowingSourceDialog = true
                } label: {
                    proofPreview
                }
                .buttonStyle(.plain)

                HStack(spacing: 10) {
                    proofActionPill(title: "Gallery", icon: "photo.on.rectangle") {
                        Task {
                            await requestPickerAccess(for: .photoLibrary)
                        }
                    }

                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        proofActionPill(title: "Camera", icon: "camera.fill") {
                            Task {
                                await requestPickerAccess(for: .camera)
                            }
                        }
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
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(ChoreQuestColors.outlineVariant, style: StrokeStyle(lineWidth: 2.5, dash: [10, 10]))
                }

            if let proofImageData, let image = UIImage(data: proofImageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                Button {
                    self.proofImageData = nil
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(ChoreQuestColors.error)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(16)
            } else {
                VStack(spacing: 18) {
                    Circle()
                        .fill(ChoreQuestColors.primary)
                        .frame(width: 82, height: 82)
                        .overlay {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                        }

                    Text("Tap to add your victory photo")
                        .font(.custom("Quicksand", size: 18).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.onSurface)

                    Text("Use the gallery or camera.")
                        .font(.custom("Quicksand", size: 14).weight(.medium))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: previewHeight)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
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

    private func proofActionPill(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.custom("Quicksand", size: 13).weight(.bold))
            .foregroundStyle(ChoreQuestColors.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(ChoreQuestColors.surfaceContainerLow)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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
