import SwiftUI
import Photos
import AVFoundation
import AVKit

/// A view that displays a detailed preview of a file from the vault. It supports different content types such as images, live photos, and videos.
/// The view allows for sharing, playback control for videos, and deletion of files.
/// It also provides a customized header and footer with various actions like navigating back, sharing content, and deleting files.
///
/// - `@EnvironmentObject` navigationManager: Handles navigation between views.
/// - `@EnvironmentObject` viewModel: Provides logic to manage the vault's contents.
/// - `file`: The file model representing the content to be displayed.
/// - `@State` livePhoto: Stores the live photo (if the file is of type live photo).
/// - `@StateObject` videoPlayerObserver: Observes the playback status of the video player.
/// - `@State` videoPlayer: Manages the video player instance for video playback.
///
struct VaultContentPreviewView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject private var viewModel: VaultViewModel
    
    private let file: FileModel
    
    @State var livePhoto: PHLivePhoto? = nil
    
    @StateObject private var videoPlayerObserver = VideoPlayerObserver()
    @State private var videoPlayer: AVPlayer? = nil
    
    init(navigationPath: Binding<NavigationPath>, file: FileModel) {
        _navigationPath = navigationPath
        self.file = file
    }
    
    var body: some View {
        ZStack {
            VStack {
                headerView
                Spacer()
                footerView
            }
            switch file.type {
            case .image:
                imageContent
            case .livePhoto:
                livePhotoContent
            case .video:
                videoContent
            default:
                Image(.imageFiller)
                    .resizable()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if file.type == .livePhoto {
                loadLivePhoto()
            } else if file.type == .video {
                setupVideoPlayer()
            }
        }
    }
    
    /// A view displaying the header with a back button and action buttons.
    private var headerView: some View {
        HStack {
            headerButton(
                action: {
                    self.navigationPath.removeLast()
                },
                image: .chevronLeft
            )
                .padding(.horizontal)
            Spacer()
        }
        .padding(.horizontal)
    }
    
    /// A view displaying the footer with share, play/pause, and delete buttons.
    private var footerView: some View {
        HStack {
            shareButton()
                .padding(.horizontal)
            if file.type == .video {
                Spacer()
                headerButton(action: {
                    toggleVideoPlayback()
                }, image: videoPlayerObserver.isPlaying ? .pauseIcon : .playIcon)
                .padding(.horizontal)
            }
            Spacer()
            headerButton(action: {
                viewModel.deleteFiles([file])
                self.navigationPath.removeLast()
            }, image: .deleteIcon)
                .padding(.horizontal)
        }
        .padding()
    }
    
    /// A reusable button for the header with an action and an image.
    private func headerButton(
        action: @escaping () -> Void,
        image: ImageResource
    ) -> some View {
        return Button(
            action: action,
            label: {
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
            }
        )
    }
    
    /// A button for sharing the current file.
    private func shareButton() -> some View {
        var url = URL(filePath: "")
        switch file.type {
        case .image:
            url = FileManagerService.shared.filesDocumentsURL?
                .appendingPathComponent(file.path) ?? URL(filePath: "")
        case .livePhoto:
            url = FileManagerService.shared.filesDocumentsURL?
                .appendingPathComponent(file.path)
                .appendingPathComponent("\(LivePhotoManager.keyPhotoKey).heic")
            ?? URL(filePath: "")
        case .video:
            url = FileManagerService.shared.filesDocumentsURL?
                .appendingPathComponent(file.path) ?? URL(filePath: "")
        default: break
        }
        
        return ShareLink(item: url) {
            Image(.shareIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
        }
    }
    
    /// A view displaying the image content.
    private var imageContent: some View {
        ZStack {
            Color.black
            AsyncImage(source: .local(path: file.path, compressedTo: 1)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Image(.imageFiller)
                    .resizable()
            }
        }
        .padding(.bottom, 60)
        .padding(.top, 40)
    }
    
    /// A view displaying the video content.
    private var videoContent: some View {
        VideoPlayer(player: videoPlayer)
            .padding(.bottom, 60)
            .padding(.top, 40)
    }
    
    /// Sets up the video player with the corresponding file's URL.
    private func setupVideoPlayer() {
        let url = FileManagerService.shared.filesDocumentsURL?.appendingPathComponent(file.path) ?? URL(filePath: "")
        videoPlayer = AVPlayer(url: url)
        videoPlayerObserver.player = videoPlayer
    }
    
    /// Toggles video playback between play and pause.
    private func toggleVideoPlayback() {
        guard let player = videoPlayer else { return }
        
        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
        }
        
        videoPlayerObserver.isPlaying = player.timeControlStatus == .playing
    }
    
    /// A view displaying live photo content, including a loading state until the live photo is ready.
    private var livePhotoContent: some View {
        ZStack {
            if livePhoto != nil {
                LivePhotoView(livephoto: $livePhoto)
            } else {
                livePhotoLoadingContent
            }
            VStack {
                HStack {
                    Image(systemName: "livephoto")
                        .padding(30)
                    Spacer()
                }
                Spacer()
            }
        }
        .padding(.bottom, 60)
        .padding(.top, 40)
    }
    
    /// A view showing the loading content while the live photo is being loaded.
    private var livePhotoLoadingContent: some View {
        ZStack {
            AsyncImage(
                source: .local(path: "\(file.path)\(LivePhotoManager.keyPhotoKey).heic", compressedTo: 1)
            ) { image in
                image
                    .resizable()
            } placeholder: {
                VStack {
                    Spacer()
                }
            }
            
            VStack {
                Spacer()
                ProgressView()
                Spacer()
            }
        }
    }
    
    /// Loads the live photo from the specified path and generates a PHLivePhoto.
    private func loadLivePhoto() {
        guard let assetUrl = FileManagerService.shared.filesDocumentsURL?.appendingPathComponent(file.path) else {
            return
        }
        let imageUrl = assetUrl.appendingPathComponent("\(LivePhotoManager.keyPhotoKey).heic")
        let videoUrl = assetUrl.appendingPathComponent("\(LivePhotoManager.videoKey).mov")
        let livePhotoManager = LivePhotoManager(assetDirectory: assetUrl)
        livePhotoManager.generate(
            from: imageUrl,
            videoURL: videoUrl,
            progress: {_ in }) { livePhoto, _ in
                self.livePhoto = livePhoto
            }
    }
}

#Preview {
    @State var navigationPath = NavigationPath()
    let file = FileModel(id: "", type: .image, path: "",
                         name: "", timeStamp: Date())
    
    VaultContentPreviewView(
        navigationPath: $navigationPath,
        file: file
    )
}
