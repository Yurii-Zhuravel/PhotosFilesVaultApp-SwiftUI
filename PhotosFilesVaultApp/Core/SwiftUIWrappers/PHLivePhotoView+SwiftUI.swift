import SwiftUI
import PhotosUI

/// A SwiftUI wrapper for `PHLivePhotoView` that allows displaying Live Photos within SwiftUI views.
struct LivePhotoView: UIViewRepresentable {
    
    /// The Live Photo to be displayed. This is a binding so the view updates when the photo changes.
    @Binding var livephoto: PHLivePhoto?

    /// Creates the underlying `PHLivePhotoView` (UIKit view).
    /// - Parameter context: Contextual information from SwiftUI.
    /// - Returns: An instance of `PHLivePhotoView`.
    ///
    func makeUIView(context: Context) -> PHLivePhotoView {
        return PHLivePhotoView()
    }

    /// Updates the `PHLivePhotoView` whenever the bound `livephoto` changes.
    /// - Parameters:
    ///   - lpView: The `PHLivePhotoView` instance to update.
    ///   - context: Contextual information (not used in this case).
    ///
    func updateUIView(_ lpView: PHLivePhotoView, context: Context) {
        lpView.livePhoto = livephoto
    }
}
