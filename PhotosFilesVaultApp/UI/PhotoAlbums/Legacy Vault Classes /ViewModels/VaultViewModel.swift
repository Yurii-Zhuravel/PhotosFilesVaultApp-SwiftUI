import Foundation
import _PhotosUI_SwiftUI
import SwiftUI
import Combine

/// Represents a media file being transferred or saved, categorized by type.
enum MediaFileTransfer {
    
    /// A photo represented as raw image data.
    case photo(imageData: Data, id: String)
    
    /// A video represented by its local URL.
    case video(videoWithUrl: URL, id: String)
    
    /// A Live Photo (combination of photo and motion) represented by `PHLivePhoto`.
    case livePhoto(phLivePhoto: PHLivePhoto, id: String)
    
    /// An audio file represented by its URL.
    case audio(url: URL, id: String)
    
    /// A PDF document.
    case pdf(url: URL, id: String)
    
    /// A spreadsheet file.
    case spreadsheet(url: URL, id: String)
    
    /// A Word document or equivalent.
    case doc(url: URL, id: String)
    
    /// A generic picture file.
    case picture(url: URL, id: String)
    
    /// A film or movie file.
    case film(url: URL, id: String)
}

/// Represents user facing media action alerts for download or deletion.
enum MediaActionAlert: Identifiable {
    
    /// Alert shown when media is successfully downloaded.
    case mediaDownloaded
    
    /// Alert shown when media is deleted.
    case mediaDeleted
    
    case folderDeleted

    /// Unique identifier for each alert case.
    var id: String {
        switch self {
        case .mediaDownloaded: return "mediaDownloaded"
        case .mediaDeleted: return "mediaDeleted"
        case .folderDeleted: return "folderDeleted"
        }
    }
}

/// ViewModel handling the business logic for the Vault Feature
class VaultViewModel: ObservableObject {
    
    /// The root folder where all vault contents reside.
    var rootFolder: FolderModel {
        fileManagerService.rootPhotoFolder
    }
    
    /// All subfolders within the root vault.
    @Published var subfolders: [FolderModel] = []
    // Dummy flag to force SwiftUI refresh
    @Published var refreshTrigger = false
    
    /// The currently selected subfolder.
    @Published var selectedSubfolder: FolderModel? = nil
    
    /// The gallery sections derived from the selected subfolder.
    @Published var selectedSubfolderSections: [VaultGalerySectionModel] = []
    
    /// The currently selected section within a folder.
    @Published var selectedSection: VaultGalerySectionModel? = nil
    
    /// Alert view state
    @Published var alertView: MediaActionAlert? = nil
    
    /// Computed property for count of total videos in selected subfolder
    var selectedSubfolderVideoCount: Int {
        guard let selectedSubfolder else { return 0 }
        let video = selectedSubfolder.items.filter { item in
            if case .file(let fileModel) = item {
                return fileModel.type == .video
            }
            return false
        }
        return video.count
    }
    
    /// Computed property for count of total photos in selected subfolder
    var selectedSubfolderPhotoCount: Int {
        guard let selectedSubfolder else { return 0 }
        let photos = selectedSubfolder.items.filter { item in
            if case .file(let fileModel) = item {
                return fileModel.type == .livePhoto || fileModel.type == .image
            }
            return false
        }
        return photos.count
    }
    
    /// Computed property for count of total videos in selected section
    var selectedSubfolderSectionVideoCount: Int {
        guard let selectedSection else { return 0 }
        let videos = selectedSection.items.filter({ $0.type == .video })
        return videos.count
    }
    
    /// Computed property for count of total photos in selected section
    var selectedSubfolderSectionPhotoCount: Int {
        guard let selectedSection else { return 0 }
        let photos = selectedSection.items.filter({ $0.type == .image || $0.type == .livePhoto })
        return photos.count
    }
    
    /// Media items selected from the photo picker.
    @Published var selectedMediaitems: [PhotosPickerItem] = []
    
    /// Flag to show confirmation for deletion from the system library.
    @Published var showsDeleteFromLibraryAlert: Bool = false
    /// Identifiers of media to delete from the photo library./
    var deleteFromLibraryItemIds: [String?] = []
    
    /// Shows loading indicator while media is being processed.
    @Published var showsLoading: Bool = false
    
    /// File management service for saving, creating, or deleting media.
    private let fileManagerService = FileManagerService.shared
    
    /// Combine cancellables bag.
    private var cancellableBag = Set<AnyCancellable>()
    
    /// Initializes the ViewModel and sets up Combine publishers for media selection handling.
    init() {
        $selectedMediaitems
            .filter { !$0.isEmpty }
            .sink(receiveCompletion: {_ in }) { [weak self] items in
                self?.saveSelectedMediaFilesFile(items)
                self?.deleteFromLibraryItemIds = items.map { $0.itemIdentifier }
                //self?.selectedMediaitems = []
            }
            .store(in: &cancellableBag)
        
        $selectedMediaitems
            .filter { !$0.isEmpty }
            .map { _ in true }
            .dropFirst()
            .eraseToAnyPublisher()
            .assign(to: \.showsLoading, on: self)
            .store(in: &cancellableBag)
        
        $selectedMediaitems
            .filter { !$0.isEmpty }
            .map { _ in true }
            .eraseToAnyPublisher()
            .delay(for: 1, scheduler: RunLoop.main)
            .sink { [weak self] newValue in
                self?.showsDeleteFromLibraryAlert = newValue
            }
            .store(in: &cancellableBag)
    }
    
    /// Saves selected media files to the vault, converting them to internal types.
    func saveSelectedMediaFilesFile(_ items: [PhotosPickerItem]) {
        Task {
            let folderToSave = selectedSubfolder ?? subfolders.first
            guard let folderToSave else { return }
            
            var transferFiles: [MediaFileTransfer] = []
            try await items.concurrentForEach { item  in
                let itemId = item.itemIdentifier ?? String(item.hashValue)
                
                if let livePhoto = try? await item.loadTransferable(type: PHLivePhoto.self) {
                    transferFiles.append(.livePhoto(phLivePhoto: livePhoto, id: itemId))
                } else if let videoData = try? await item.loadTransferable(type: Movie.self) {
                    transferFiles.append(.video(videoWithUrl: videoData.url, id: itemId))
                } else if let imageData = try? await item.loadTransferable(type: Data.self) {
                    transferFiles.append(.photo(imageData: imageData, id: itemId))
                }
            }
            try await fileManagerService.save(transferFiles, in: folderToSave)
            await updateContent()
        }
    }
    
    /// Creates a new folder in the vault root.
    func createNewFolder(name: String) {
        Task {
            let folderModel = FolderModel(
                path: rootFolder.name,
                name: name,
                items: [],
                timeStamp: Date(),
                filesCount: 0,
                foldersCount: 0,
                isEditable: true
            )
            
            try await fileManagerService.createFolder(folderModel, in: rootFolder)
            rootFolder
            await updateContent()
        }
    }
    
    /// Deletes the specified files from the currently selected subfolder and updates the UI.
    ///
    /// - Parameter files: An array of `FileModel` objects to be deleted.
    ///
    func deleteFiles(_ files: [FileModel]) {
        Task {
            guard let selectedSubfolder else { return }
            await fileManagerService.deleteFiles(files, from: selectedSubfolder)
            await updateContent()
            DispatchQueue.main.async {
                self.alertView = .mediaDeleted
            }
        }
    }
    
    func deleteFolder(_ folder: FolderModel) {
        Task {
            await fileManagerService.deleteFolder(folder)
            await MainActor.run {
                subfolders.removeAll { inputFolder in
                    return inputFolder.name == folder.name
                }
                // Toggle the flag to notify SwiftUI
                refreshTrigger.toggle()
            }
            await updateContent()
            
            DispatchQueue.main.async {
                self.alertView = .folderDeleted
            }
        }
    }
    
    /// Refreshes the UI content by fetching the latest subfolders and their respective sections.
    /// Must be called from the main actor since it updates UI-bound properties.
    ///
    @MainActor
    func updateContent() {
        self.fetchSubfolders()
        self.fetchSelectedSubfolderSections()
        self.showsLoading = false
    }
    
    /// Retrieves the list of subfolders from the root folder and updates the `subfolders` property.
    /// Attempts to retain the currently selected subfolder if it still exists in the new list.
    ///
    func fetchSubfolders() {
        var selectedSubfolerIndex: Int?
        if let selectedSubfolder {
            selectedSubfolerIndex = subfolders.firstIndex(of: selectedSubfolder)
        }
        subfolders = rootFolder.items.compactMap {
            switch $0 {
            case .folder(let model): return model
            default: return nil
            }
        }
        
        if let selectedSubfolerIndex, subfolders.count > 0 {
            self.selectedSubfolder = subfolders[selectedSubfolerIndex]
        } else {
            self.selectedSubfolder = nil
        }
    }
    
    /// Updates the `selectedSubfolderSections` by reading the latest data from the selected subfolder.
    /// Retains the previously selected section if it still exists in the updated sections.
    ///
    func fetchSelectedSubfolderSections() {
        guard let selectedSubfolder else { return }
        var selectedSectionIndex: Int?
        if let selectedSection {
            selectedSectionIndex = selectedSubfolderSections.firstIndex(of: selectedSection)
        }
        
        self.selectedSubfolder = fileManagerService.readDataLog(for: selectedSubfolder)
        selectedSubfolderSections = splitFolderFilesByMonths(folder: self.selectedSubfolder ?? selectedSubfolder)
        
        if let selectedSectionIndex, selectedSubfolderSections.count > 0 {
            self.selectedSection = selectedSubfolderSections[selectedSectionIndex]
        } else {
            self.selectedSection = nil
        }
    }
    
    /// Asynchronously removes media items from the user's photo library based on their local identifiers.
    /// Clears `deleteFromLibraryItemIds` after deletion.
    ///
    func removeMediaItemFromPhotoLibrary() async {
        await deleteFromLibraryItemIds.asyncForEach { itemId in
            guard let itemId else { return }
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else { return }
                
                DispatchQueue.global(qos: .userInitiated).async {
                PHPhotoLibrary.shared().performChanges {
                        let assets = PHAsset.fetchAssets(
                            withLocalIdentifiers: [itemId],
                            options: nil
                        )
                        PHAssetChangeRequest.deleteAssets(assets)
                    }
                }
            }
        }
        
        deleteFromLibraryItemIds = []
    }
    
    /// Saves a list of media files to the user's Photos library.
    /// Supports saving images, videos, and Live Photos.
    ///
    /// - Parameter files: An array of `FileModel` representing the media to be saved.
    ///
    func saveToPhotosLibrary(files: [FileModel]) {
        files.forEach { fileModel in
            switch fileModel.type {
            case .image:
                guard let imageUrl = fileManagerService.filesDocumentsURL?
                    .appendingPathComponent(fileModel.path),
                      let imageData = try? Data(contentsOf: imageUrl),
                      let image = UIImage(data: imageData) else { break }
                UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
            case .livePhoto:
                guard let videoUrl = fileManagerService.filesDocumentsURL?
                    .appendingPathComponent(fileModel.path)
                    .appendingPathComponent("\(LivePhotoManager.videoKey).mov"),
                      let imageUrl = fileManagerService.filesDocumentsURL?
                    .appendingPathComponent(fileModel.path)
                    .appendingPathComponent("\(LivePhotoManager.keyPhotoKey).heic"),
                      let imageData = try? Data(contentsOf: imageUrl) else { break }
                
                saveLivePhotoToPhotosLibrary(
                    stillImageData: imageData,
                    livePhotoMovieURL: videoUrl
                )
            case .video:
                guard let videoUrl = fileManagerService.filesDocumentsURL?
                    .appendingPathComponent(fileModel.path) else { break }
                
                PHPhotoLibrary.requestAuthorization { status in
                    guard status == .authorized else { return }
                    DispatchQueue.global(qos: .userInitiated).async {
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
                        }) { saved, error in
                            guard saved else { return }
                            let fetchOptions = PHFetchOptions()
                            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                            _ = PHAsset.fetchAssets(with: .video, options: fetchOptions).firstObject
                            // fetchResult is your latest video PHAsset
                            // To fetch latest image  replace .video with .image
                        }
                    }
                }
            default:
                break
            }
        }
        
        alertView = .mediaDownloaded
    }
    
    /// Saves a Live Photo to the user's Photos library using the provided image data and video URL.
    ///
    /// - Parameters:
    ///   - stillImageData: The data for the still image component of the Live Photo.
    ///   - livePhotoMovieURL: The URL for the video component of the Live Photo.
    ///
    private func saveLivePhotoToPhotosLibrary(
        stillImageData: Data,
        livePhotoMovieURL: URL
    ) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, data: stillImageData, options: nil)
                    
                    let options = PHAssetResourceCreationOptions()
                    options.shouldMoveFile = true
                    creationRequest.addResource(with: .pairedVideo, fileURL: livePhotoMovieURL, options: options)
                }) { success, error in
                    // Handle completion.
                }
            }
        }
    }
    
    /// Splits the files in the given folder into monthly sections.
    ///
    /// - Parameter folder: The folder containing mixed items (files and folders).
    /// - Returns: An array of `VaultGalerySectionModel` grouped by year and month, sorted in descending order.
    ///
    private func splitFolderFilesByMonths(folder: FolderModel) -> [VaultGalerySectionModel] {
        let models = folder.items.compactMap { item in
            if case .file(let fileModel) = item {
                return fileModel
            }
            return nil
        }
        let grouped = models.sliced(by: [.year, .month], for: \.timeStamp)
        return grouped.map { date, filesModels in
            VaultGalerySectionModel(
                dateString: getMonthsString(from: date),
                date: date,
                items: filesModels
            )
        }
        .sorted { lhs, rhs in
            lhs.date > rhs.date
        }
    }
    
    /// Formats a given date into a "yyyy MMMM" string ("2025 May").
    ///
    /// - Parameter date: The date to format.
    /// - Returns: A string representing the year and full month name.
    ///
    private func getMonthsString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MMMM"
        return formatter.string(from: date)
    }
}
