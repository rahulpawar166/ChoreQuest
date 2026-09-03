//
//  AvatarTokenViews.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI
import UIKit

struct AvatarTokenPickerSection: View {
    let title: String
    @Binding var selectedAvatar: AvatarOption
    let selectedImageData: Binding<Data?>?

    init(
        title: String,
        selectedAvatar: Binding<AvatarOption>,
        selectedImageData: Binding<Data?>? = nil
    ) {
        self.title = title
        self._selectedAvatar = selectedAvatar
        self.selectedImageData = selectedImageData
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label(title, systemImage: "person.crop.circle.fill")
                    .font(.custom("Quicksand", size: 20).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)

                Spacer()

                Text("\(AvatarOption.all.count) Avatars")
                    .font(.custom("Quicksand", size: 12).weight(.bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(ChoreQuestColors.secondary)
                    .foregroundStyle(Color(hex: 0x6f5100))
                    .clipShape(Capsule())
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 12
            ) {
                if let selectedImageData {
                    AvatarPhotoPickerCard(
                        imageData: selectedImageData,
                        title: "Add Photo",
                        accentColor: ChoreQuestColors.primary
                    )
                }

                ForEach(AvatarOption.all) { avatar in
                    AvatarTokenCard(
                        avatar: avatar,
                        isSelected: selectedAvatar == avatar
                    ) {
                        selectedAvatar = avatar
                        if let imageName = avatar.imageName {
                            selectedImageData?.wrappedValue = Self.profileData(for: imageName)
                        }
                    }
                }
            }
        }
    }

    private static func profileData(for imageName: String) -> Data? {
        guard let image = UIImage(named: imageName) else { return nil }
        return QuestImageProcessor.jpegData(from: image, purpose: .profile)
    }
}

struct AvatarTokenCard: View {
    let avatar: AvatarOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isSelected ? ChoreQuestColors.surfaceContainer : ChoreQuestColors.surfaceContainerLow)
                    .frame(height: 92)
                    .overlay {
                        AvatarArtwork(
                            imageName: avatar.imageName,
                            fallbackIconName: avatar.iconName,
                            colorHex: avatar.colorHex,
                            cornerRadius: 18,
                            padding: 8
                        )
                    }
                    .overlay(alignment: .topTrailing) {
                        if isSelected {
                            Circle()
                                .fill(ChoreQuestColors.primary)
                                .frame(width: 24, height: 24)
                                .overlay {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .offset(x: 6, y: -6)
                        }
                    }

                Text(avatar.name)
                    .font(.custom("Quicksand", size: 12).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
            }
            .padding(6)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isSelected ? ChoreQuestColors.primary : .clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
    }
}

struct HeroAvatarPreview: View {
    let imageData: Data?
    let avatar: AvatarOption
    let size: CGFloat

    var body: some View {
        if let imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
        } else if let imageName = avatar.imageName {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
        } else {
            Circle()
                .fill(Color(hex: avatar.colorHex).opacity(0.14))
                .frame(width: size, height: size)
                .overlay {
                    Image(systemName: avatar.iconName)
                        .font(.system(size: size * 0.42, weight: .bold))
                        .foregroundStyle(Color(hex: avatar.colorHex))
                }
        }
    }
}

struct LocalAvatarPickerSection: View {
    let title: String
    let options: [LocalAvatarOption]
    @Binding var selectedImageData: Data?
    @State private var selectedAvatarID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label(title, systemImage: "person.crop.circle.fill")
                    .font(.custom("Quicksand", size: 20).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)

                Spacer()

                Text("\(options.count) Avatars")
                    .font(.custom("Quicksand", size: 12).weight(.bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(ChoreQuestColors.secondary)
                    .foregroundStyle(Color(hex: 0x6f5100))
                    .clipShape(Capsule())
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 12
            ) {
                AvatarPhotoPickerCard(
                    imageData: $selectedImageData,
                    title: "Add Photo",
                    accentColor: ChoreQuestColors.primary
                ) {
                    selectedAvatarID = nil
                }

                ForEach(options) { option in
                    LocalAvatarCard(
                        option: option,
                        isSelected: selectedAvatarID == option.id
                    ) {
                        selectedAvatarID = option.id
                        selectedImageData = Self.profileData(for: option.imageName)
                    }
                }
            }
        }
    }

    private static func profileData(for imageName: String) -> Data? {
        guard let image = UIImage(named: imageName) else { return nil }
        return QuestImageProcessor.jpegData(from: image, purpose: .profile)
    }
}

private struct AvatarPhotoPickerCard: View {
    @Binding var imageData: Data?
    let title: String
    let accentColor: Color
    var onPhotoSelected: (() -> Void)? = nil

    @State private var sourceType: UIImagePickerController.SourceType?
    @State private var isShowingSourceDialog = false
    @State private var permissionAlert: QuestMediaPermissionAlert?
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            isShowingSourceDialog = true
        } label: {
            VStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(ChoreQuestColors.surfaceContainerLow)
                    .frame(height: 92)
                    .overlay {
                        ZStack(alignment: .bottomTrailing) {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(accentColor.opacity(0.14))
                                .overlay {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundStyle(accentColor)
                                }

                            Circle()
                                .fill(ChoreQuestColors.secondary)
                                .frame(width: 30, height: 30)
                                .overlay {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Color(hex: 0x6f5100))
                                }
                                .offset(x: 4, y: 4)
                        }
                        .padding(8)
                    }

                Text(title)
                    .font(.custom("Quicksand", size: 12).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
            }
            .padding(6)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
        .confirmationDialog("Add Photo", isPresented: $isShowingSourceDialog) {
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

            if imageData != nil {
                Button("Remove Photo", role: .destructive) {
                    imageData = nil
                }
            }
        }
        .sheet(item: $sourceType) { source in
            CameraLibraryImagePicker(sourceType: source) { data in
                imageData = data
                if data != nil {
                    onPhotoSelected?()
                }
            }
        }
        .alert(item: $permissionAlert) { alert in
            if alert.opensSettings {
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    primaryButton: .default(Text("Open Settings")) {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        openURL(url)
                    },
                    secondaryButton: .cancel()
                )
            } else {
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK"))
                )
            }
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

private struct LocalAvatarCard: View {
    let option: LocalAvatarOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isSelected ? ChoreQuestColors.surfaceContainer : ChoreQuestColors.surfaceContainerLow)
                    .frame(height: 92)
                    .overlay {
                        AvatarArtwork(
                            imageName: option.imageName,
                            fallbackIconName: "person.crop.circle.fill",
                            colorHex: option.colorHex,
                            cornerRadius: 18,
                            padding: 8
                        )
                    }
                    .overlay(alignment: .topTrailing) {
                        if isSelected {
                            Circle()
                                .fill(ChoreQuestColors.primary)
                                .frame(width: 24, height: 24)
                                .overlay {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .offset(x: 6, y: -6)
                        }
                    }

                Text(option.name)
                    .font(.custom("Quicksand", size: 12).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
            }
            .padding(6)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isSelected ? ChoreQuestColors.primary : .clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AvatarArtwork: View {
    let imageName: String?
    let fallbackIconName: String
    let colorHex: UInt
    let cornerRadius: CGFloat
    let padding: CGFloat

    var body: some View {
        if let imageName {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .padding(padding)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            Circle()
                .fill(Color(hex: colorHex).opacity(0.14))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: fallbackIconName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color(hex: colorHex))
                }
        }
    }
}
