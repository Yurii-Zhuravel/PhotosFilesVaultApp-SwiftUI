import UIKit
import Photos

/// An enumeration representing possible errors from the `FileManagerService`.
enum FileManagerServiceError: LocalizedError {
    
    /// Indicates that the URL for a file could not be created.
    case urlCreationFailed
    
    /// Indicates a failure occurred while saving the file.
    case fileSavingFailed
    
    /// Indicates that the app failed to create a required directory.
    case directoryCreationFailed
    
    /// Indicates a failure occurred while generating a Live Photo.
    case livePhotoGenerationFailed
    
    /// Indicates the app does not have permission to access the specified URL.
    case permissionDenied
    
    /// A localized description of the error, suitable for displaying to users.
    var errorDescription: String? {
        switch self {
        case .urlCreationFailed: return "Failed to create url for file"
        case .fileSavingFailed: return "File saving was failed"
        case .directoryCreationFailed: return "Directory creation was failed"
        case .livePhotoGenerationFailed: return "Failed to generate live photo asset data"
        case .permissionDenied: return "Permission denied to access the url"
        }
    }
}

/// A service responsible for handling all file-related operations such as creating folders, saving media files, and managing root folders.
final class FileManagerService {
    
    /// Shared singleton instance of `FileManagerService`.
    static let shared: FileManagerService = FileManagerService()
    
    private let fileManager: FileManager = FileManager.default
    
    /// The URL to the app's document directory.
    var filesDocumentsURL: URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    private let dataLogKeyName: String = "dataLog"
    private let rootPhotoFolderName: String = "PhotoVault"
    private let rootFilesFolderName: String = "FilesVault"
    
    /// Root folder that stores photo folders.
    private(set) var rootPhotoFolder: FolderModel!
    
    /// Root folder that stores file folders.
    private(set) var rootFilesFolder: FolderModel!
    
    /// Private initializer to enforce singleton pattern.
    private init() {
        initiateValues()
    }
    
    // MARK: - Folder Creation
    
    /// Creates a new photo folder within a specified holder folder.
    ///
    /// - Parameters:
    ///   - folder: The `FolderModel` representing the new folder to create.
    ///   - holderFolder: The parent folder in which to create the new folder.
    /// - Returns: A Boolean indicating success.
    /// - Throws: `FileManagerServiceError` if URL creation or directory creation fails.
    ///
    @discardableResult
    func createFolder(
        _ folder: FolderModel,
        in holderFolder: FolderModel
    ) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            var holderFolder = holderFolder
            
            guard let holderFolderUrl = getFolderUrl(holderFolder) else {
                print("\(holderFolder.name) folder url couldn't be found")
                continuation.resume(throwing: FileManagerServiceError.urlCreationFailed)
                return
            }
            
            let folderName = folder.name // ! Do not remove white spaces! Can't delete it later!
            let newFolderUrl = holderFolderUrl
                .appendingPathComponent(folderName)
            
            do {
                try fileManager.createDirectory(
                    at: newFolderUrl,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                
                holderFolder.items.append(.folder(folder))
                holderFolder.foldersCount += 1
                
                if holderFolder != rootPhotoFolder {
                    rootPhotoFolder.foldersCount += 1
                    writeToDataLog(for: rootPhotoFolder)
                } else {
                    rootPhotoFolder = holderFolder
                }
                writeToDataLog(for: holderFolder)
                writeToDataLog(for: folder)
                continuation.resume(returning: true)
            } catch {
                print("Creating folder failed: \(error.localizedDescription)")
                continuation.resume(throwing: FileManagerServiceError.directoryCreationFailed)
            }
        }
    }
    
    /// Creates a new general file folder within a specified holder folder.
    ///
    /// - Parameters:
    ///   - folder: The `FolderModel` representing the new folder to create.
    ///   - holderFolder: The parent folder in which to create the new folder.
    /// - Returns: A Boolean indicating success.
    /// - Throws: `FileManagerServiceError` if URL creation or directory creation fails.
    ///
    @discardableResult
    func createFilesFolder(
        _ folder: FolderModel,
        in holderFolder: FolderModel
    ) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            var holderFolder = holderFolder
            
            guard let holderFolderUrl = getFolderUrl(holderFolder) else {
                print("\(holderFolder.name) folder url couldn't be found")
                continuation.resume(throwing: FileManagerServiceError.urlCreationFailed)
                return
            }
            
            let folderName = folder.name.filter { !$0.isWhitespace }
            let newFolderUrl = holderFolderUrl
                .appendingPathComponent(folderName)
            
            do {
                try fileManager.createDirectory(
                    atPath: newFolderUrl.path(),
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                
                holderFolder.items.append(.folder(folder))
                holderFolder.foldersCount += 1
                
                if holderFolder != rootFilesFolder {
                    rootFilesFolder.foldersCount += 1
                    writeToDataLog(for: rootFilesFolder)
                } else {
                    rootFilesFolder = holderFolder
                }
                writeToDataLog(for: holderFolder)
                writeToDataLog(for: folder)
                continuation.resume(returning: true)
            } catch {
                print("Creating folder failed: \(error.localizedDescription)")
                continuation.resume(throwing: FileManagerServiceError.directoryCreationFailed)
            }
        }
    }
    
    // MARK: - File Saving

    /// Saves an array of media files (photo, video, live photo) into the specified folder.
    ///
    /// - Parameters:
    ///   - mediafileTransfers: An array of `MediaFileTransfer` representing files to save.
    ///   - folder: The `FolderModel` where the files should be saved.
    ///   - saveToPhotoFolder: Indicates whether the files are saved to the photo vault.
    /// - Returns: A Boolean indicating whether all files were saved successfully.
    /// - Throws: Errors if file saving fails.
    ///
    @discardableResult
    func save(
        _ mediafileTransfers: [MediaFileTransfer],
        in folder: FolderModel, saveToPhotoFolder: Bool = true) async throws -> Bool {
            guard var folder = readDataLog(for: folder) else { return false }
            let holderFolderPath = getFolderPath(folder)
            
            try await mediafileTransfers.concurrentForEach { [weak self] mediafileTransfer in
                guard let self else { return }
                
                var fileModel: FileModel
                var newFileCreated: Bool
                switch mediafileTransfer {
                    
                case .photo(let imageData, let id):
                    let id = id.replacing("/", with: "-")
                    let path = "\(holderFolderPath)/\(id).jpg"
                    fileModel = FileModel(
                        id: id,
                        type: .image,
                        path: path,
                        name: id,
                        timeStamp: Date()
                    )
                    newFileCreated = try await save(image: imageData, fileModel: fileModel)
                    
                    if folder.thubnailPath == nil {
                        setupThumbnail(path: path, for: &folder)
                    }
                    
                case .video(let videoWithUrl, let id):
                    let id = id.replacing("/", with: "-")
                    let path = "\(holderFolderPath)/\(videoWithUrl.lastPathComponent)"
                    fileModel = FileModel(
                        id: id,
                        type: .video,
                        path: path,
                        name: id,
                        timeStamp: Date()
                    )
                    newFileCreated = try await save(video: videoWithUrl, fileModel: fileModel)
                    
                case .livePhoto(let phLivePhoto, let id):
                    let id = id.replacing("/", with: "-")
                    let path = "\(holderFolderPath)/\(id)"
                    
                    fileModel = FileModel(
                        id: id,
                        type: .livePhoto,
                        path: path,
                        name: id,
                        timeStamp: Date()
                    )
                    newFileCreated = try await save(phLivePhoto: phLivePhoto, fileModel: fileModel)
                    
                    if folder.thubnailPath == nil {
                        setupThumbnail(path: "\(path)/\(LivePhotoManager.keyPhotoKey).heic", for: &folder)
                    }
                    
                case .audio(url: let file, id: let id):
                    let id = id.replacing("/", with: "-")
                    let path = "\(holderFolderPath)/\(file.lastPathComponent)"
                    fileModel = FileModel(
                        id: id,
                        type: .audio,
                        path: path,
                        name: id,
                        timeStamp: Date()
                    )
                    newFileCreated = try await save(file: file, fileModel: fileModel)
                    
                case .film(url: let file, id: let id):
                    let id = id.replacing("/", with: "-")
                    let path = "\(holderFolderPath)/\(file.lastPathComponent)"
                    fileModel = FileModel(
                        id: id,
                        type: .film,
                        path: path,
                        name: id,
                        timeStamp: Date()
                    )
                    newFileCreated = try await save(file: file, fileModel: fileModel)
                    
                case .picture(url: let file, id: let id):
                    let id = id.replacing("/", with: "-")
                    let path = "\(holderFolderPath)/\(file.lastPathComponent)"
                    fileModel = FileModel(
                        id: id,
                        type: .picture,
                        path: path,
                        name: id,
                        timeStamp: Date()
                    )
                    newFileCreated = try await save(file: file, fileModel: fileModel)
                    
                case .pdf(url: let file, id: let id):
                    let id = id.replacing("/", with: "-")
                    let path = "\(holderFolderPath)/\(file.lastPathComponent)"
                    fileModel = FileModel(
                        id: id,
                        type: .pdf,
                        path: path,
                        name: id,
                        timeStamp: Date()
                    )
                    newFileCreated = try await save(file: file, fileModel: fileModel)
                    
                case .doc(url: let file, id: let id):
                    let id = id.replacing("/", with: "-")
                    let path = "\(holderFolderPath)/\(file.lastPathComponent)"
                    fileModel = FileModel(
                        id: id,
                        type: .word,
                        path: path,
                        name: id,
                        timeStamp: Date()
                    )
                    newFileCreated = try await save(file: file, fileModel: fileModel)
                    
                case .spreadsheet(url: let file, id: let id):
                    let id = id.replacing("/", with: "-")
                    let path = "\(holderFolderPath)/\(file.lastPathComponent)"
                    fileModel = FileModel(
                        id: id,
                        type: .spreadsheet,
                        path: path,
                        name: id,
                        timeStamp: Date()
                    )
                    newFileCreated = try await save(file: file, fileModel: fileModel)
                }
                
                if newFileCreated {
                    folder.items.append(.file(fileModel))
                    folder.filesCount += 1
                    if saveToPhotoFolder {
                        rootPhotoFolder.filesCount += 1
                    } else {
                        rootFilesFolder.filesCount += 1
                    }
                }
            }
            
            if saveToPhotoFolder {
                writeToDataLog(for: rootPhotoFolder)
                writeToDataLog(for: folder)
                rootPhotoFolder = readDataLog(for: rootPhotoFolder)
            } else {
                writeToDataLog(for: rootFilesFolder)
                writeToDataLog(for: folder)
                rootFilesFolder = readDataLog(for: rootFilesFolder)
            }
            return true
        }
    
    /// Saves an image to the file system.
    ///
    /// - Parameters:
    ///   - data: The image data to save.
    ///   - fileModel: The file model describing the save path.
    /// - Returns: `true` if the file was successfully saved, `false` if the file already exists.
    /// - Throws: `FileManagerServiceError.urlCreationFailed` or `FileManagerServiceError.fileSavingFailed`.
    ///
    @discardableResult
    private func save(
        image data: Data,
        fileModel: FileModel
    ) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            guard let url = filesDocumentsURL?.appendingPathComponent(fileModel.path) else {
                continuation.resume(throwing: FileManagerServiceError.urlCreationFailed)
                return
            }
            
            if fileManager.fileExists(atPath: url.path()) {
                continuation.resume(returning: false)
                return
            }
            
            do {
                try data.write(to: url, options: .atomic)
                continuation.resume(returning: true)
            } catch {
                print("File saving failed: \(error)")
                continuation.resume(throwing: FileManagerServiceError.fileSavingFailed)
                return
            }
        }
    }
    
    /// Saves a video file to the file system.
    ///
    /// - Parameters:
    ///   - url: The URL of the video to save.
    ///   - fileModel: The file model describing the save path.
    /// - Returns: `true` if the file was successfully saved, `false` if the file already exists.
    /// - Throws: `FileManagerServiceError.urlCreationFailed` or `FileManagerServiceError.fileSavingFailed`.
    ///
    @discardableResult
    func save(
        video url: URL,
        fileModel: FileModel
    ) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            guard let savingUrl = filesDocumentsURL?.appendingPathComponent(fileModel.path) else {
                continuation.resume(throwing: FileManagerServiceError.urlCreationFailed)
                return
            }
            
            if fileManager.fileExists(atPath: savingUrl.path()) {
                continuation.resume(returning: false)
                return
            }
            
            do {
                try fileManager.copyItem(at: url, to: savingUrl)
                continuation.resume(returning: true)
            } catch {
                print(error)
                continuation.resume(throwing: FileManagerServiceError.fileSavingFailed)
                return
            }
        }
    }
    
    /// Saves a general file to the file system, with support for security-scoped resources.
    ///
    /// - Parameters:
    ///   - url: The URL of the file to save.
    ///   - fileModel: The file model describing the save path.
    /// - Returns: `true` if the file was successfully saved, `false` if the file already exists.
    /// - Throws: `FileManagerServiceError.urlCreationFailed`, `FileManagerServiceError.fileSavingFailed`, or `FileManagerServiceError.permissionDenied`.
    ///
    @discardableResult
    func save(
        file url: URL,
        fileModel: FileModel
    ) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            if (CFURLStartAccessingSecurityScopedResource(url as CFURL)) {
                guard let savingUrl = filesDocumentsURL?.appendingPathComponent(fileModel.path.filter { !$0.isWhitespace }) else {
                    continuation.resume(throwing: FileManagerServiceError.urlCreationFailed)
                    return
                }
                
                if fileManager.fileExists(atPath: savingUrl.path()) {
                    continuation.resume(returning: false)
                    return
                }
                
                do {
                    try fileManager.copyItem(at: url, to: savingUrl)
                    continuation.resume(returning: true)
                } catch {
                    print(error)
                    continuation.resume(throwing: FileManagerServiceError.fileSavingFailed)
                    return
                }
                CFURLStopAccessingSecurityScopedResource(url as CFURL)
            }
            else {
                print("Permission error!")
                continuation.resume(throwing: FileManagerServiceError.permissionDenied)
                return
            }
        }
    }
    
    /// Saves a `PHLivePhoto` to the file system using a custom `LivePhotoManager`.
    ///
    /// - Parameters:
    ///   - phLivePhoto: The `PHLivePhoto` instance to extract and save resources from.
    ///   - fileModel: The file model describing the save path.
    /// - Returns: `true` if the Live Photo was successfully saved, `false` if it already exists.
    /// - Throws: `FileManagerServiceError.urlCreationFailed` or `FileManagerServiceError.livePhotoGenerationFailed`.
    ///
    @discardableResult
    func save(
        phLivePhoto: PHLivePhoto,
        fileModel: FileModel
    ) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            guard let livePhotoAssetUrl = filesDocumentsURL?.appendingPathComponent(fileModel.path, isDirectory: true) else {
                print("livePhotoAssetUrl couldn't be created")
                continuation.resume(throwing: FileManagerServiceError.urlCreationFailed)
                return
            }
            
            var isDirectory:ObjCBool = true
            if fileManager.fileExists(atPath: livePhotoAssetUrl.path(), isDirectory: &isDirectory) {
                continuation.resume(returning: false)
                return
            }
            
            let livePhotoManager = LivePhotoManager(assetDirectory: livePhotoAssetUrl)
            livePhotoManager.extractResources(from: phLivePhoto) { livePhotoResources in
                guard let _ = livePhotoResources else {
                    continuation.resume(throwing: FileManagerServiceError.livePhotoGenerationFailed)
                    return
                }
                continuation.resume(returning: true)
            }
        }
    }
    
    /// Deletes multiple files from a specific folder and updates the associated metadata.
    ///
    /// - Parameters:
    ///   - files: An array of `FileModel` instances representing the files to delete.
    ///   - folder: The folder from which the files are to be deleted.
    /// - Returns: `true` when the operation completes.
    ///
    @discardableResult
    func deleteFiles(
        _ files: [FileModel],
        from folder: FolderModel
    ) async -> Bool {
        await withCheckedContinuation { continuation in
            var folder = folder
            files.forEach { file in
                guard deleteFile(file) else { return }
                
                folder.items.removeAll { item in
                    if case .file(let folderFile) = item {
                        return folderFile == file
                    }
                    return false
                }
                rootPhotoFolder.filesCount -= 1
                folder.filesCount -= 1
            }
            writeToDataLog(for: rootPhotoFolder)
            writeToDataLog(for: folder)
            rootPhotoFolder = readDataLog(for: rootPhotoFolder)
            continuation.resume(returning: true)
        }
    }
    
    @discardableResult
    func deleteFolder(_ folder: FolderModel) async -> Bool {
        await withCheckedContinuation { continuation in
            var folder = folder
            
            guard let url = filesDocumentsURL?
                .appendingPathComponent(folder.path)
                .appendingPathComponent(folder.name),
                  fileManager.fileExists(atPath: url.path(percentEncoded: false)) else {
                print("Folder deletion failed: File couldn't be found => \(folder.name)")
                continuation.resume(returning: false)
                return
            }
            do {
                try fileManager.removeItem(at: url)
            
                rootPhotoFolder.filesCount -= folder.filesCount
                rootPhotoFolder.items.removeAll { item in
                    switch item {
                    case .file(_):
                        return false
                    case  .folder(let inputFolder):
                        return inputFolder.name == folder.name
                    }
                }
                removeDataFromLog(for: rootPhotoFolder, folderToRemove: folder.name)
                
                continuation.resume(returning: true)
            } catch {
                print("Folder deletion failed: \(error)")
                continuation.resume(returning: false)
            }
        }
    }
    
    // MARK: - File Deletion
    
    /// Deletes multiple files from the secure files vault and updates folder metadata.
    ///
    /// - Parameters:
    ///   - files: An array of `FileModel` instances representing the files to delete.
    ///   - folder: The folder from which the files are to be deleted.
    /// - Returns: `true` when the operation completes.
    ///
    @discardableResult
    func deleteFromFilesVault(
        _ files: [FileModel],
        from folder: FolderModel
    ) async -> Bool {
        await withCheckedContinuation { continuation in
            var folder = folder
            files.forEach { file in
                guard deleteFileFromVault(file) else { return }
                
                folder.items.removeAll { item in
                    if case .file(let folderFile) = item {
                        return folderFile == file
                    }
                    return false
                }
                rootFilesFolder.filesCount -= 1
                folder.filesCount -= 1
            }
            writeToDataLog(for: rootFilesFolder)
            writeToDataLog(for: folder)
            rootFilesFolder = readDataLog(for: rootFilesFolder)
            continuation.resume(returning: true)
        }
    }
    
    /// Deletes a file from the file system if it exists.
    /// - Parameter fileModel: The file to delete.
    /// - Returns: `true` if deletion was successful, otherwise `false`.
    ///
    private func deleteFile(_ fileModel: FileModel) -> Bool {
        guard let url = filesDocumentsURL?.appendingPathComponent(fileModel.path),
              fileManager.fileExists(atPath: url.path()) else {
            print("File deletion failed: File couldn't be found")
            return false
        }
        do {
            try fileManager.removeItem(at: url)
            return true
        } catch {
            print("File deletion failed: \(error)")
            return false
        }
    }
    
    /// Deletes a file from the app's vault directory.
    ///
    /// - Parameter fileModel: The `FileModel` representing the file to delete.
    /// - Returns: `true` if the file was successfully deleted, `false` otherwise.
    ///
    private func deleteFileFromVault(_ fileModel: FileModel) -> Bool {
        guard let url = filesDocumentsURL?.appendingPathComponent(fileModel.path.filter { !$0.isWhitespace }),
              fileManager.fileExists(atPath: url.path()) else {
            print("File deletion failed: File couldn't be found")
            return false
        }
        do {
            try fileManager.removeItem(at: url)
            return true
        } catch {
            print("File deletion failed: \(error)")
            return false
        }
    }
    
    // MARK: - Other Helper Functions
    
    /// Reads the data log JSON for the given folder and decodes it into a `FolderModel`.
    /// - Parameter folder: The folder for which to read the data log.
    /// - Returns: A `FolderModel` if the log file exists and is successfully decoded, otherwise `nil`.
    ///
    func readDataLog(for folder: FolderModel) -> FolderModel? {
        guard let holderFolderUrl = getFolderUrl(folder) else {
            print("\(folder.name) folder url couldn't be found")
            return nil
        }
        
        let logDataFileUrl = holderFolderUrl.appendingPathComponent("\(dataLogKeyName).json")
        
        return readDataLog(url: logDataFileUrl)
    }
    
    /// Initializes the root file and photo folders if `filesDocumentsURL` is available.
    private func initiateValues() {
        guard let filesDocumentsURL else {
            print("filesDocumentsURL couldn't be found")
            return
        }
        
        self.rootFilesFolder = buildRootFilesFolder(filesDocumentsURL: filesDocumentsURL)
        self.rootPhotoFolder = buildRootPhotoFolder(filesDocumentsURL: filesDocumentsURL)
    }
    
    /// Builds the root photo folder by reading its data log or creating a default one.
    /// - Parameter filesDocumentsURL: The base URL for the documents directory.
    /// - Returns: A `FolderModel` representing the root photo folder.
    ///
    private func buildRootPhotoFolder(filesDocumentsURL: URL) -> FolderModel {
        let photoDataLogFileUrl = filesDocumentsURL
            .appendingPathComponent(rootPhotoFolderName)
            .appendingPathComponent("\(dataLogKeyName).json")
        
        if let rootPhotoFolder = readDataLog(url: photoDataLogFileUrl) {
            return rootPhotoFolder
        } else {
            return createRootFolder(for: rootPhotoFolderName, filesDocumentsURL: filesDocumentsURL)
        }
    }
    
    /// Builds the root files folder by reading its data log or creating a default one.
    /// - Parameter filesDocumentsURL: The base URL for the documents directory.
    /// - Returns: A `FolderModel` representing the root files folder.
    ///
    private func buildRootFilesFolder(filesDocumentsURL: URL) -> FolderModel {
        let filesDataLogFileUrl = filesDocumentsURL
            .appendingPathComponent(rootFilesFolderName)
            .appendingPathComponent("\(dataLogKeyName).json")
        
        if let rootPhotoFolder = readDataLog(url: filesDataLogFileUrl) {
            return rootPhotoFolder
        } else {
            return createRootFolder(for: rootFilesFolderName, filesDocumentsURL: filesDocumentsURL)
        }
    }
    
    /// Creates a new root folder and a default subfolder inside it. Also writes their data logs to disk.
    /// - Parameters:
    ///   - folderName: Name of the root folder to create.
    ///   - filesDocumentsURL: The base directory for file storage.
    /// - Returns: A `FolderModel` representing the created root folder.
    ///
    private func createRootFolder(for folderName: String, filesDocumentsURL: URL) -> FolderModel {
        let defailtFolderName = "Main Folder"
        do {
            let rootDirectoryUrl = filesDocumentsURL.appendingPathComponent(folderName.filter { !$0.isWhitespace })
            try fileManager.createDirectory(atPath: rootDirectoryUrl.path(), withIntermediateDirectories: true, attributes: nil)
            
            let defaultFolderUrl = rootDirectoryUrl.appendingPathComponent(defailtFolderName.filter { !$0.isWhitespace })
            try fileManager.createDirectory(atPath: defaultFolderUrl.path(), withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Creating root folder failed: \(error.localizedDescription)")
        }
        
        let defaultFolderModel = FolderModel(
            path: folderName,
            name: defailtFolderName,
            items: [],
            timeStamp: Date(),
            filesCount: 0,
            foldersCount: 0,
            isEditable: false
        )
        
        let rootFolderModel = FolderModel(
            path: "",
            name: folderName,
            items: [.folder(defaultFolderModel)],
            timeStamp: Date(),
            filesCount: 0,
            foldersCount: 1,
            isEditable: false
        )
        
        writeToDataLog(for: rootFolderModel)
        writeToDataLog(for: defaultFolderModel)
        
        return rootFolderModel
    }
    
    /// Reads and decodes the folder model from the specified JSON file URL.
    /// - Parameter url: The URL of the JSON file.
    /// - Returns: A `FolderModel` if decoding is successful, otherwise `nil`.
    ///
    private func readDataLog(url: URL) -> FolderModel? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let jsonData = try decoder.decode(FolderModel.self, from: data)
            return jsonData
        } catch {
            print("error:\(error)")
            return nil
        }
    }
    
    /// Writes a `FolderModel` as JSON data to the corresponding log file on disk.
    /// - Parameter folder: The folder model to encode and save.
    ///
    private func writeToDataLog(for folder: FolderModel) {
        guard let holderFolderUrl = getFolderUrl(folder) else {
            print("\(folder.name) folder url couldn't be found")
            return
        }
        
        let logDataFileUrl = holderFolderUrl.appendingPathComponent("\(dataLogKeyName).json")
        
        do {
            let encodedData = try JSONEncoder().encode(folder)
            try encodedData.write(to: logDataFileUrl)
        }
        catch {
            print("Failed to write JSON data: \(error.localizedDescription)")
        }
    }
    
    private func removeDataFromLog(for folder: FolderModel, folderToRemove: String) {
        guard let holderFolderUrl = getFolderUrl(folder) else {
            print("\(folder.name) folder url couldn't be found")
            return
        }
        
        let logDataFileUrl = holderFolderUrl.appendingPathComponent("\(dataLogKeyName).json")
        
        removeFolderFromLog(folderName: folderToRemove, logUrl: logDataFileUrl)
    }
    
    func removeFolder(named folderName: String, from folder: inout FolderModel) {
        folder.items.removeAll { item in
            switch item {
            case .folder(let dict):
                // Remove if any folder matches name
                if dict.name == folderName {
                    return true
                }
                return false
            case .file(_):
                return false
            }
        }
    }

    // MARK: - Remove folder from JSON log on disk
    func removeFolderFromLog(folderName: String, logUrl: URL) {
        guard let data = try? Data(contentsOf: logUrl),
              var root = try? JSONDecoder().decode(FolderModel.self, from: data) else {
            print("Failed to load or decode JSON log")
            return
        }

        removeFolder(named: folderName, from: &root)
        
        do {
            let encoded = try JSONEncoder().encode(root)
            try encoded.write(to: logUrl)
            print("Removed '\(folderName)' from log")
        } catch {
            print("Failed to write JSON: \(error)")
        }
    }
    
    /// Constructs the full folder URL based on the folder's name and path.
    /// - Parameter folder: The folder model for which to construct the URL.
    /// - Returns: The full `URL` to the folder location, or `nil` if `filesDocumentsURL` is unavailable.
    ///
    private func getFolderUrl(_ folder: FolderModel) -> URL? {
        guard let filesDocumentsURL else {
            print("filesDocumentsURL couldn't be found")
            return nil
        }
        
        var holderFolderUrl = filesDocumentsURL
        if !folder.path.isEmpty {
            holderFolderUrl = filesDocumentsURL
                .appendingPathComponent(folder.path.filter { !$0.isWhitespace })
                .appendingPathComponent(folder.name.filter { !$0.isWhitespace })
        } else {
            holderFolderUrl = filesDocumentsURL
                .appendingPathComponent(folder.name.filter { !$0.isWhitespace })
        }
        
        return holderFolderUrl
    }
    
    /// Generates a folder path string by joining the folder’s path and name, removing whitespaces.
    /// - Parameter folder: The folder model.
    /// - Returns: A sanitized relative path string for the folder.
    ///
    private func getFolderPath(_ folder: FolderModel) -> String {
        var result = ""
        if !folder.path.isEmpty {
            result = "\(folder.path.filter { !$0.isWhitespace })/\(folder.name.filter { !$0.isWhitespace })"
        } else {
            result = "\(folder.name.filter { !$0.isWhitespace })"
        }
        return result
    }
    
    /// Sets the thumbnail path for a folder and updates it in the root photo folder.
    ///
    /// - Parameters:
    ///   - path: The file path to be used as the thumbnail.
    ///   - folder: The folder to which the thumbnail will be applied.
    ///
    private func setupThumbnail(path: String, for folder: inout FolderModel) {
        folder.thubnailPath = path
        
        if let folderIndex = rootPhotoFolder.items.firstIndex(where: { item in
            if case .folder(let folderModel) = item {
                return folderModel == folder
            }
            return false
        }) {
            rootPhotoFolder.items.remove(at: folderIndex)
            rootPhotoFolder.items.insert(.folder(folder), at: folderIndex)
        }
        
    }
    
    // MARK: - Old single file saving functions
    
    /// Saves an image file to a specified folder.
    ///
    /// - Parameters:
    ///   - imageData: The image data to be saved.
    ///   - id: A unique identifier for the file.
    ///   - folder: The folder in which the file will be stored.
    /// - Returns: `true` if saving was successful; throws error otherwise.
    ///
    @discardableResult
    func save(
        imageData: Data,
        id: String,
        in folder: FolderModel
    ) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            var folder = folder
            let holderFolderPath = getFolderPath(folder)
            
            let id = id.replacing("/", with: "-")
            let path = "\(holderFolderPath)/\(id).jpg"
            
            let imageModel = FileModel(
                id: id,
                type: .image,
                path: path,
                name: id,
                timeStamp: Date()
            )
            
            folder.items.append(.file(imageModel))
            folder.filesCount += 1
            
            if folder.thubnailPath == nil {
                folder.thubnailPath = path
                
                if let folderIndex = rootPhotoFolder.items.firstIndex(where: { item in
                    if case .folder(let folderModel) = item {
                        return folderModel == folder
                    }
                    return false
                }) {
                    rootPhotoFolder.items.remove(at: folderIndex)
                    rootPhotoFolder.items.insert(.folder(folder), at: folderIndex)
                }
            }
            
            rootPhotoFolder.filesCount += 1
            
            guard let url = filesDocumentsURL?.appendingPathComponent(imageModel.path) else {
                continuation.resume(throwing: FileManagerServiceError.urlCreationFailed)
                return
            }
            
            if fileManager.fileExists(atPath: url.path()) {
                continuation.resume(returning: true)
                return
            }
            
            do {
                try imageData.write(to: url, options: .atomic)
            } catch {
                print("File saving failed: \(error)")
                continuation.resume(throwing: FileManagerServiceError.fileSavingFailed)
                return
            }
            
            writeToDataLog(for: rootPhotoFolder)
            writeToDataLog(for: folder)
            rootPhotoFolder = readDataLog(for: rootPhotoFolder)
            continuation.resume(returning: true)
        }
    }
    
    /// Saves a video file to a specified folder.
    ///
    /// - Parameters:
    ///   - url: The local URL of the video file.
    ///   - id: A unique identifier for the file.
    ///   - folder: The folder in which the file will be stored.
    /// - Returns: `true` if saving was successful; throws error otherwise.
    ///
    @discardableResult
    func save(
        videoWithUrl url: URL,
        id: String,
        in folder: FolderModel
    ) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            var folder = folder
            let holderFolderPath = getFolderPath(folder)
            
            let id = id.replacing("/", with: "-")
            let path = "\(holderFolderPath)/\(url.lastPathComponent)"
            
            let videoModel = FileModel(
                id: id,
                type: .video,
                path: path,
                name: id,
                timeStamp: Date()
            )
            
            folder.items.append(.file(videoModel))
            folder.filesCount += 1
            
            rootPhotoFolder.filesCount += 1
            
            guard let savingUrl = filesDocumentsURL?.appendingPathComponent(path) else {
                continuation.resume(throwing: FileManagerServiceError.urlCreationFailed)
                return
            }
            
            if fileManager.fileExists(atPath: savingUrl.path()) {
                continuation.resume(returning: true)
                return
            }
            
            do {
                try fileManager.copyItem(at: url, to: savingUrl)
            } catch {
                print(error)
                continuation.resume(throwing: FileManagerServiceError.fileSavingFailed)
                return
            }
            
            writeToDataLog(for: rootPhotoFolder)
            writeToDataLog(for: folder)
            rootPhotoFolder = readDataLog(for: rootPhotoFolder)
            continuation.resume(returning: true)
        }
    }
    
    /// Saves a `PHLivePhoto` to a specified folder.
    ///
    /// - Parameters:
    ///   - phLivePhoto: The `PHLivePhoto` object to be saved.
    ///   - id: A unique identifier for the file.
    ///   - folder: The folder in which the file will be stored.
    /// - Returns: `true` if saving was successful; throws error otherwise.
    ///
    @discardableResult
    func save(
        phLivePhoto: PHLivePhoto,
        id: String,
        in folder: FolderModel
    ) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            var folder = folder
            let holderFolderPath = getFolderPath(folder)
            
            let id = id.replacing("/", with: "-")
            let path = "\(holderFolderPath)/\(id)"
            
            let livePhotoModel = FileModel(
                id: id,
                type: .livePhoto,
                path: path,
                name: id,
                timeStamp: Date()
            )
            
            folder.items.append(.file(livePhotoModel))
            folder.filesCount += 1
            
            if folder.thubnailPath == nil {
                folder.thubnailPath = "\(path)/\(LivePhotoManager.keyPhotoKey).heic"
                
                if let folderIndex = rootPhotoFolder.items.firstIndex(where: { item in
                    if case .folder(let folderModel) = item {
                        return folderModel == folder
                    }
                    return false
                }) {
                    rootPhotoFolder.items.remove(at: folderIndex)
                    rootPhotoFolder.items.insert(.folder(folder), at: folderIndex)
                }
            }
            
            rootPhotoFolder.filesCount += 1
            
            guard let livePhotoAssetUrl = filesDocumentsURL?.appendingPathComponent(path, isDirectory: true) else {
                print("livePhotoAssetUrl couldn't be created")
                continuation.resume(throwing: FileManagerServiceError.urlCreationFailed)
                return
            }
            
            var isDirectory:ObjCBool = true
            if fileManager.fileExists(atPath: livePhotoAssetUrl.path(), isDirectory: &isDirectory) {
                continuation.resume(returning: true)
                return
            }
            
            let livePhotoManager = LivePhotoManager(assetDirectory: livePhotoAssetUrl)
            
            livePhotoManager.extractResources(from: phLivePhoto) { [weak self] livePhotoResources in
                guard let self,
                      let _ = livePhotoResources else { return }
                self.writeToDataLog(for: self.rootPhotoFolder)
                self.writeToDataLog(for: folder)
                self.rootPhotoFolder = self.readDataLog(for: rootPhotoFolder)
                continuation.resume(returning: true)
            }
        }
    }
}
