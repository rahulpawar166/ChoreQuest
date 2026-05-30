//
//  QuestImagePicker.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import SwiftUI
import UIKit

struct QuestImagePickerCard: View {
    let title: String
    let subtitle: String
    let fallbackSystemImage: String
    let accentColor: Color
    @Binding var imageData: Data?

    @State private var sourceType: UIImagePickerController.SourceType?
    @State private var isShowingSourceDialog = false

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

                HStack(spacing: 8) {
                    miniActionButton(label: "Gallery", icon: "photo.on.rectangle") {
                        sourceType = .photoLibrary
                    }

                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        miniActionButton(label: "Camera", icon: "camera.fill") {
                            sourceType = .camera
                        }
                    }
                }
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
                sourceType = .photoLibrary
            }

            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") {
                    sourceType = .camera
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
}

private struct CameraLibraryImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (Data?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
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
        let onImagePicked: (Data?) -> Void

        init(onImagePicked: @escaping (Data?) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let editedImage = info[.editedImage] as? UIImage
            let originalImage = info[.originalImage] as? UIImage
            let selectedImage = editedImage ?? originalImage
            let data = selectedImage?.jpegData(compressionQuality: 0.75)

            picker.dismiss(animated: true) {
                self.onImagePicked(data)
            }
        }
    }
}

extension UIImagePickerController.SourceType: @retroactive Identifiable {
    public var id: Int { rawValue }
}
