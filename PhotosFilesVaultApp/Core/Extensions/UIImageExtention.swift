import UIKit

extension UIImage {
    
    /// Resizes the image by a specified percentage of its original size.
    /// - Parameter percentage: The percentage by which to resize the image (e.g., 0.5 for 50% of the original size).
    /// - Parameter isOpaque: A boolean indicating if the image is opaque (default is `true`).
    /// - Returns: A new `UIImage` resized by the given percentage, or `nil` if the resizing fails.
    ///
    func resized(withPercentage percentage: CGFloat, isOpaque: Bool = true) -> UIImage? {
        let canvas = CGSize(width: size.width * percentage, height: size.height * percentage)
        let format = imageRendererFormat
        format.opaque = isOpaque
        return UIGraphicsImageRenderer(size: canvas, format: format).image {
            _ in draw(in: CGRect(origin: .zero, size: canvas))
        }
    }

    /// Compresses the image to fit a specified file size (in kilobytes).
    /// The compression quality is adjusted iteratively until the image's file size is below the target size, with an optional margin.
    /// - Parameter kb: The target file size in kilobytes.
    /// - Parameter allowedMargin: The allowable margin over the target file size (default is 0.2, or 20% over).
    /// - Returns: The image data compressed to fit within the target size.
    ///
    func compress(to kb: Int, allowedMargin: CGFloat = 0.2) -> Data {
        let bytes = kb * 1024
        var compression: CGFloat = 1.0
        let step: CGFloat = 0.05
        var holderImage = self
        var complete = false
        while(!complete) {
            if let data = holderImage.jpegData(compressionQuality: 1.0) {
                let ratio = data.count / bytes
                if data.count < Int(CGFloat(bytes) * (1 + allowedMargin)) {
                    complete = true
                    return data
                } else {
                    let multiplier:CGFloat = CGFloat((ratio / 5) + 1)
                    compression -= (step * multiplier)
                }
            }
            
            guard let newImage = holderImage.resized(withPercentage: compression) else { break }
            holderImage = newImage
        }
        return Data()
    }
}
