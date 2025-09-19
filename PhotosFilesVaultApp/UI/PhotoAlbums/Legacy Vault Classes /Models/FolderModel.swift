import Foundation

/// A model representing a folder that may contain files and subfolders.
struct FolderModel: Codable {
    
    /// An item inside a folder, which can be either a file or a subfolder.
    enum FolderItem: Codable {
        
        /// A subfolder item.
        case folder(FolderModel)
        
        /// A subfolder item.
        case file(FileModel)
    }
    
    /// The file system path or storage location of the folder.
    let path: String
    
    /// The display name of the folder.
    let name: String
    
    /// The list of items contained within the folder.
    var items: [FolderItem]
    
    /// The timestamp representing when the folder was created or modified.
    var timeStamp: Date
    
    /// The path to a thumbnail image representing the folder (optional).
    var thubnailPath: String?
    
    /// The total number of files in the folder.
    var filesCount: Int
    
    /// The total number of subfolders in the folder./
    var foldersCount: Int
    
    /// Computed property that returns only the subfolders from the items list.
    var subfolders: [FolderModel] {
        items.compactMap { item in
            if case .folder(let folderModel) = item {
                return folderModel
            }
            return nil
        }
    }
    
    var isEditable: Bool
}

// MARK: - Hashable Conformance

extension FolderModel: Hashable {
    static func == (lhs: FolderModel, rhs: FolderModel) -> Bool {
        lhs.name == rhs.name &&
        lhs.path == rhs.path &&
        lhs.timeStamp == rhs.timeStamp
    }
}

// MARK: - Preview Data

extension FolderModel {
    
    /// A preview instance of a `FolderModel` for testing or SwiftUI previews.
    static let previewModel = FolderModel(
        path: "",
        name: "Main Folder",
        items: preivewItems,
        timeStamp: Date(),
        filesCount: 2,
        foldersCount: 2,
        isEditable: true
    )
    
    /// A preview list of folder items including files and subfolders.
    static let preivewItems: [FolderItem] = [
        .file(FileModel(
            id: "",
            type: .image,
            path: "",
            name: "",
            timeStamp: Date()
        )),
        .file(FileModel(
            id: "",
            type: .image,
            path: "",
            name: "",
            timeStamp: Date()
        )),
        .folder(FolderModel(
            path: "",
            name: "Main Folder",
            items: [],
            timeStamp: Date(),
            filesCount: 0,
            foldersCount: 0,
            isEditable: true
        )),
        .folder(FolderModel(
            path: "",
            name: "Default Folder",
            items: [],
            timeStamp: Date(),
            filesCount: 0,
            foldersCount: 0,
            isEditable: true
        )),
    ]
}

// MARK: - FolderItem Hashable Conformance

extension FolderModel.FolderItem: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .folder(let folderModel):
            hasher.combine(folderModel.name)
            hasher.combine(folderModel.path)
            hasher.combine(folderModel.timeStamp)
        case .file(let fileModel):
            hasher.combine(fileModel.id)
            hasher.combine(fileModel.timeStamp)
        }
    }
    
    static func == (lhs: FolderModel.FolderItem, rhs: FolderModel.FolderItem) -> Bool {
        switch (lhs, rhs) {
        case (.file(let lhsFileModel), .file(let rhsFileModel)):
            return lhsFileModel.id == rhsFileModel.id &&
            lhsFileModel.timeStamp == rhsFileModel.timeStamp
        case (.folder(let lhsFolderModel), .folder(let rhsFolderModel)):
            return lhsFolderModel.name == rhsFolderModel.name &&
            lhsFolderModel.path == rhsFolderModel.path &&
            lhsFolderModel.timeStamp == rhsFolderModel.timeStamp
        default:
            return false
        }
    }
}
