//
//  QuestImageProcessor.swift
//  ChoreQuest
//

import UIKit

enum QuestImagePurpose {
    case profile
    case proof

    var maximumDimension: CGFloat {
        switch self {
        case .profile: return 384
        case .proof: return 1_200
        }
    }

    var maximumBytes: Int {
        switch self {
        case .profile: return 72_000
        case .proof: return 550_000
        }
    }
}

enum QuestImageProcessor {
    static func jpegData(from image: UIImage, purpose: QuestImagePurpose) -> Data? {
        jpegData(
            from: image,
            maximumDimension: purpose.maximumDimension,
            maximumBytes: purpose.maximumBytes
        )
    }

    static func profileData(from data: Data?, maximumBytes: Int = QuestImagePurpose.profile.maximumBytes) -> Data? {
        guard let data, let image = UIImage(data: data) else { return nil }
        return jpegData(
            from: image,
            maximumDimension: QuestImagePurpose.profile.maximumDimension,
            maximumBytes: maximumBytes
        )
    }

    private static func jpegData(
        from sourceImage: UIImage,
        maximumDimension: CGFloat,
        maximumBytes: Int
    ) -> Data? {
        var targetDimension = maximumDimension
        let qualitySteps: [CGFloat] = [0.82, 0.7, 0.58, 0.46, 0.34, 0.24]
        var smallestData: Data?

        while targetDimension >= 128 {
            let image = resized(sourceImage, maximumDimension: targetDimension)

            for quality in qualitySteps {
                guard let data = image.jpegData(compressionQuality: quality) else { continue }
                if smallestData == nil || data.count < (smallestData?.count ?? Int.max) {
                    smallestData = data
                }
                if data.count <= maximumBytes {
                    return data
                }
            }

            targetDimension *= 0.78
        }

        return smallestData
    }

    private static func resized(_ image: UIImage, maximumDimension: CGFloat) -> UIImage {
        let longestSide = max(image.size.width, image.size.height)
        guard longestSide > maximumDimension else { return image }

        let scale = maximumDimension / longestSide
        let targetSize = CGSize(
            width: max(1, floor(image.size.width * scale)),
            height: max(1, floor(image.size.height * scale))
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: targetSize, format: format).image { context in
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fill(CGRect(origin: .zero, size: targetSize))
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
