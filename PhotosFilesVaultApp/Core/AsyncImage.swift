import SwiftUI
import Combine
import Foundation

/// Enum to represent the source of the image. It can be from a remote URL, a local file, or a captured image.
enum ImageSource {
    
    /// Represents a remote image from a URL.
    case remote(url: URL?)
    
    /// Represents a local image from a file path, with an optional compression ratio.
    case local(path: String?, compressedTo: CGFloat)
    
    /// Represents a captured image (e.g., from the camera), with an optional compression ratio.
    case captured(image: UIImage, compressedTo: CGFloat = 1.0)
}

/// Enum to represent the loading phase of the image.
/// It tracks whether the image loading is in progress, successful, or failed.
enum AsyncImagePhase {
    
    /// The phase when the image is not loaded yet.
    case empty
    
    /// The phase when the image has been successfully loaded.
    case success(Image)
    
    /// The phase when an error occurs while loading the image.
    case failure(Error)
}

private class ImageLoader: ObservableObject {
    
    /// A URL session configuration used for making image loading network requests.
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        let session = URLSession(configuration: configuration)
        return session
    }()

    /// Enum for the possible errors encountered during image loading.
    private enum LoaderError: Swift.Error {
        case missingURL
        case failedToDecodeFromData
    }
    
    /// Published property that tracks the current state of the image loading process.
    @Published var phase = AsyncImagePhase.empty

    /// A list of subscriptions used for managing ongoing network requests.
    private var subscriptions: [AnyCancellable] = []
    
    /// The source from which the image is being loaded (remote, local, captured).
    private let source: ImageSource

    /// Initializer that accepts an `ImageSource` to determine the image loading source.
    init(source: ImageSource) {
        self.source = source
    }
    
    /// Deinitializer that cancels any ongoing image loading tasks.
    deinit {
        cancel()
    }
    
    /// Asynchronously loads the image from the given source and updates the `phase` property.
    /// This method handles different image sources such as remote, local, or captured images.
    @MainActor
    func load() async {
        let url: URL

        switch source {
        case .local(let path, let compression):
            if let image = try? await loadFromFile(with: path, compression: compression) {
                phase = .success(Image(uiImage: image))
                return
            } else {
                phase = .failure(LoaderError.missingURL)
                return
            }
        case .remote(let theUrl):
            if let theUrl = theUrl {
                url = theUrl
            } else {
                phase = .failure(LoaderError.missingURL)
                return
            }
        case .captured(let uiImage, let compression):
            if let compressedUIImage = uiImage.resized(withPercentage: compression) {
                phase = .success(Image(uiImage: compressedUIImage))
            } else {
                phase = .failure(LoaderError.failedToDecodeFromData)
            }
            return
        }

        ImageLoader.session.dataTaskPublisher(for: url)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.phase = .failure(error)
                }
            }, receiveValue: {
                if let image = UIImage(data: $0.data) {
                    self.phase = .success(Image(uiImage: image))
                } else {
                    self.phase = .failure(LoaderError.failedToDecodeFromData)
                }
            })
            .store(in: &subscriptions)
    }
    
    /// Loads an image from a local file and applies compression.
    /// - Parameters:
    ///   - path: The file path of the image.
    ///   - compression: The compression ratio to apply to the image.
    /// - Returns: A compressed `UIImage` if successful.
    /// - Throws: A `LoaderError` if the image could not be loaded or compressed.
    ///
    private func loadFromFile(with path: String?, compression: CGFloat) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            guard let path,
               let url = FileManagerService.shared.filesDocumentsURL?.appendingPathComponent(path),
               let data = try? Data(contentsOf: url),
                  let uiImage = UIImage(data: data)?.resized(withPercentage: compression) else {
                continuation.resume(throwing: LoaderError.failedToDecodeFromData)
                return
            }
            continuation.resume(returning: uiImage)
        }
        
    }
    
    /// Cancels all active image loading tasks by invalidating the subscriptions.
    func cancel() {
        subscriptions.forEach { sub in
            sub.cancel()
        }
    }

}

struct AsyncImage<Content>: View where Content: View {
    
    /// A `StateObject` that manages the image loading process using `ImageLoader`.
    @StateObject fileprivate var loader: ImageLoader
    
    /// A closure that defines the content to display based on the loading phase.
    @ViewBuilder private var content: (AsyncImagePhase) -> Content

    /// Initializes an `AsyncImage` view with the image source and a content closure.
    /// - Parameters:
    ///   - source: The source from which the image is to be loaded (e.g., remote, local, captured).
    ///   - content: A closure that defines the view to display based on the `AsyncImagePhase`.
    ///
    init(source: ImageSource, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        _loader = .init(wrappedValue: ImageLoader(source: source))
        self.content = content
    }

    var body: some View {
        content(loader.phase).onAppear {
            Task {
                await loader.load()
            }
        }
    }
}

extension AsyncImage {
    /// Initializes an `AsyncImage` view with both a content and a placeholder view.
    /// - Parameters:
    ///   - source: The source from which the image is to be loaded (e.g., remote, local, captured).
    ///   - content: A closure that defines the view to display when the image is successfully loaded.
    ///   - placeholder: A closure that defines the view to display when the image is not loaded yet.
    ///
    init<I, P>(
        source: ImageSource,
        @ViewBuilder content: @escaping (Image) -> I,
        @ViewBuilder placeholder: @escaping () -> P) where
        Content == _ConditionalContent<I, P>,
        I : View,
        P : View {
        self.init(source: source) { phase in
            switch phase {
            case .success(let image):
                content(image)
            case .empty, .failure:
                placeholder()
            }
        }
    }
}
