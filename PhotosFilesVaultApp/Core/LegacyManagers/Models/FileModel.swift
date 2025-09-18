import Foundation

/// A model representing a file with associated metadata.
struct FileModel: Codable {
    
    /// A unique identifier for the file.
    let id: String
    
    /// The type of file.
    let type: FileType
    
    /// The file system path or storage path of the file.
    let path: String
    
    /// The display name of the file.
    let name: String
    
    /// The creation or modification date of the file.
    let timeStamp: Date
}

/// Represents the type of a file.
///
/// This enum is used to categorize the file types for a `FileModel`.
///
enum FileType: Codable {
    
    /// An image file.
    case image
    
    /// A Live Photo, available only on Apple devices.
    case livePhoto
    
    /// A video file,
    case video
    
    /// An audio file,
    case audio
    
    /// A PDF document.
    case pdf
    
    /// A Word document,
    case word
    
    /// A spreadsheet file,
    case spreadsheet
    
    /// A generic picture file.
    case picture
    
    /// A film or movie file, possibly long-duration video.
    case film
    
    /// An empty or unknown file type.
    case empty
}

/// Conformance to `Hashable` and `Identifiable` for use in SwiftUI and other collections.
extension FileModel: Hashable, Identifiable {}
