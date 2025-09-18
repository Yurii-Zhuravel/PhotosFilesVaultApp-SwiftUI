import CoreTransferable
internal import UniformTypeIdentifiers

/// A model representing a transferable movie file, conforming to the `Transferable` protocol.
///
struct Movie: Transferable {
    
    /// The local URL of the movie file./
    let url: URL
    
    /// Defines how the movie should be exported and imported in transfer operations.
    ///
    /// - Uses `.movie` as the content type.
    /// - On export: the file located at `url` is sent.
    /// - On import: the file is copied to a temporary location before initializing a `Movie` instance.
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            // Export the movie file.
            SentTransferredFile(movie.url)
        } importing: { received in
            // Import the movie file by copying it to a temporary directory.
            let fileName = received.file.lastPathComponent
            let copy: URL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            // Ensure no existing file with the same name.
            if FileManager.default.fileExists(atPath: copy.path()) {
                try FileManager.default.removeItem(at: copy)
            }
            
            try FileManager.default.copyItem(at: received.file, to: copy)
            return .init(url: copy)
        }
    }
}
