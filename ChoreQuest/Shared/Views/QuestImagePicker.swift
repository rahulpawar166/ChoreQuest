//
//  QuestImagePicker.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI
import UIKit
import Photos
import AVFoundation

struct QuestImagePickerCard: View {
    let title: String
    let subtitle: String
    let fallbackSystemImage: String
    let accentColor: Color
    @Binding var imageData: Data?

    @State private var sourceType: UIImagePickerController.SourceType?
    @State private var isShowingSourceDialog = false
    @State private var permissionAlert: QuestMediaPermissionAlert?
    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(spacing: 18) {
            Button {
                isShowingSourceDialog = true
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(ChoreQuestColors.surfaceContainerHigh)
                        .frame(width: 118, height: 118)
                        .overlay {
                            previewContent
                        }

                    Circle()
                        .fill(ChoreQuestColors.secondary)
                        .frame(width: 34, height: 34)
                        .overlay {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: 0x6f5100))
                        }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.custom("Quicksand", size: 16).weight(.bold))
                    .foregroundStyle(ChoreQuestColors.onSurface)

                Text(subtitle)
                    .font(.custom("Quicksand", size: 15).weight(.medium))
                    .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
//
//                HStack(spacing: 8) {
//                    miniActionButton(label: "Gallery", icon: "photo.on.rectangle") {
//                        Task {
//                            await requestPickerAccess(for: .photoLibrary)
//                        }
//                    }
//
//                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
//                        miniActionButton(label: "Camera", icon: "camera.fill") {
//                            Task {
//                                await requestPickerAccess(for: .camera)
//                            }
//                        }
//                    }
//                }
            }
        }
        .padding(18)
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
                .foregroundStyle(ChoreQuestColors.outlineVariant)
        )
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

    @ViewBuilder
    private var previewContent: some View {
        if let imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 118, height: 118)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        } else {
            Image(systemName: fallbackSystemImage)
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(accentColor)
        }
    }

    private func miniActionButton(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.custom("Quicksand", size: 12).weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(ChoreQuestColors.surfaceContainerLow)
            .foregroundStyle(ChoreQuestColors.primary)
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

struct CameraLibraryImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let processingPurpose: QuestImagePurpose
    let onImagePicked: (Data?) -> Void

    init(
        sourceType: UIImagePickerController.SourceType,
        processingPurpose: QuestImagePurpose = .profile,
        onImagePicked: @escaping (Data?) -> Void
    ) {
        self.sourceType = sourceType
        self.processingPurpose = processingPurpose
        self.onImagePicked = onImagePicked
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(processingPurpose: processingPurpose, onImagePicked: onImagePicked)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let processingPurpose: QuestImagePurpose
        let onImagePicked: (Data?) -> Void

        init(processingPurpose: QuestImagePurpose, onImagePicked: @escaping (Data?) -> Void) {
            self.processingPurpose = processingPurpose
            self.onImagePicked = onImagePicked
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let editedImage = info[.editedImage] as? UIImage
            let originalImage = info[.originalImage] as? UIImage
            let selectedImage = editedImage ?? originalImage
            let data = selectedImage.flatMap {
                QuestImageProcessor.jpegData(from: $0, purpose: processingPurpose)
            }

            picker.dismiss(animated: true) {
                self.onImagePicked(data)
            }
        }
    }
}

extension UIImagePickerController.SourceType: @retroactive Identifiable {
    public var id: Int { rawValue }
}

struct QuestMediaPermissionAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let opensSettings: Bool
}

enum QuestMediaPermissionService {
    enum AccessResult {
        case granted
        case showAlert(QuestMediaPermissionAlert)
    }

    static func requestAccess(for sourceType: UIImagePickerController.SourceType) async -> AccessResult {
        switch sourceType {
        case .camera:
            return await requestCameraAccess()
        case .photoLibrary, .savedPhotosAlbum:
            return await requestPhotoLibraryAccess()
        @unknown default:
            return .showAlert(
                QuestMediaPermissionAlert(
                    title: "Unavailable Source",
                    message: "This photo source is not available on this device.",
                    opensSettings: false
                )
            )
        }
    }

    private static func requestCameraAccess() async -> AccessResult {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return .showAlert(
                QuestMediaPermissionAlert(
                    title: "Camera Unavailable",
                    message: "This device does not have an available camera.",
                    opensSettings: false
                )
            )
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .granted
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            return granted ? .granted : deniedCameraAlert()
        case .denied, .restricted:
            return deniedCameraAlert()
        @unknown default:
            return deniedCameraAlert()
        }
    }

    private static func requestPhotoLibraryAccess() async -> AccessResult {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized, .limited:
            return .granted
        case .notDetermined:
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            switch status {
            case .authorized, .limited:
                return .granted
            case .denied, .restricted:
                return deniedPhotoLibraryAlert()
            case .notDetermined:
                return deniedPhotoLibraryAlert()
            @unknown default:
                return deniedPhotoLibraryAlert()
            }
        case .denied, .restricted:
            return deniedPhotoLibraryAlert()
        @unknown default:
            return deniedPhotoLibraryAlert()
        }
    }

    private static func deniedCameraAlert() -> AccessResult {
        .showAlert(
            QuestMediaPermissionAlert(
                title: "Camera Access Needed",
                message: "Allow camera access in Settings to take proof photos for chores.",
                opensSettings: true
            )
        )
    }

    private static func deniedPhotoLibraryAlert() -> AccessResult {
        .showAlert(
            QuestMediaPermissionAlert(
                title: "Photo Library Access Needed",
                message: "Allow photo library access in Settings to attach proof photos for chores.",
                opensSettings: true
            )
        )
    }
}
