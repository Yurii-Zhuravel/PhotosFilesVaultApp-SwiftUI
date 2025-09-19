import UIKit
import AVFoundation
import MobileCoreServices
import Photos

/// A utility class that provides functionality for generating, extracting, and saving Live Photos.
class LivePhotoManager {
    
    // MARK: - Types
    
    /// A tuple containing the image and video file URLs used in a Live Photo.
    typealias LivePhotoResources = (pairedImage: URL, pairedVideo: URL)
    
    // MARK: - Constants
    
    /// The file name key used for the key photo.
    static let keyPhotoKey: String = "keyPhoto"
    
    /// The file name key used for the paired video.
    static let videoKey: String = "video"
    
    // MARK: - Properties
    
    /// A background dispatch queue for Live Photo operations.
    private let queue = DispatchQueue(label: "livePhotoQueue", attributes: .concurrent)
    
    /// The directory where processed Live Photo assets are stored.
    let assetDirectory: URL
    
    /// The temporary cache directory used to store intermediate files during Live Photo generation.
    lazy private var cacheDirectory: URL? = {
        if let cacheDirectoryURL = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            let fullDirectory = cacheDirectoryURL.appendingPathComponent("livePhoto", isDirectory: true)
            if !FileManager.default.fileExists(atPath: fullDirectory.absoluteString) {
                try? FileManager.default.createDirectory(at: fullDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            return fullDirectory
        }
        return nil
    }()
    
    
    // MARK: - Initialization

    /// Initializes the manager with a specific directory for storing Live Photo assets.
    ///
    /// - Parameter assetDirectory: The directory to store generated assets.
    ///
    init(assetDirectory: URL) {
        self.assetDirectory = assetDirectory
        if !FileManager.default.fileExists(atPath: assetDirectory.absoluteString) {
            try? FileManager.default.createDirectory(at: assetDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    deinit {
        // Optionally clear cache on deallocation
        // clearCache()
    }
    
    // MARK: - Private Methods

    /// Removes all cached files used during the Live Photo generation process.
    private func clearCache() {
        if let cacheDirectory = cacheDirectory {
            try? FileManager.default.removeItem(at: cacheDirectory)
        }
    }
    
    // MARK: - Public API

    /// Extracts the underlying photo and video resources from a given `PHLivePhoto`.
    ///
    /// - Parameters:
    ///   - livePhoto: The `PHLivePhoto` instance to extract resources from.
    ///   - completion: A closure called with the extracted resources or nil if extraction fails.
    ///
    public func extractResources(
        from livePhoto: PHLivePhoto,
        completion: @escaping (LivePhotoResources?) -> Void) {
        queue.async {
            self.extractResources(from: livePhoto, to: self.assetDirectory, completion: completion)
        }
    }
    
    /// Generates a `PHLivePhoto` from a photo and video combination.
    ///
    /// - Parameters:
    ///   - imageURL: An optional image URL to use as the key photo. If nil, a still frame will be extracted from the video.
    ///   - videoURL: The URL of the video to be used in the Live Photo.
    ///   - progress: A closure providing progress updates during processing (0.0 to 1.0).
    ///   - completion: A closure called with the generated `PHLivePhoto` and its resources or nil if generation fails.
    ///
    public func generate(
        from imageURL: URL?,
        videoURL: URL,
        progress: @escaping (CGFloat) -> Void,
        completion: @escaping (PHLivePhoto?, LivePhotoResources?) -> Void
    ) {
        queue.async {
            self.generatePHLivePhoto(from: imageURL, videoURL: videoURL, progress: progress, completion: completion)
        }
    }
    
    /// Saves a Live Photo to the user’s photo library.
    ///
    /// - Parameters:
    ///   - resources: The photo and video components of the Live Photo.
    ///   - completion: A closure called with a success flag indicating whether the save succeeded.
    ///
    public func saveToLibrary(_ resources: LivePhotoResources, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            let creationRequest = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            creationRequest.addResource(with: PHAssetResourceType.pairedVideo, fileURL: resources.pairedVideo, options: options)
            creationRequest.addResource(with: PHAssetResourceType.photo, fileURL: resources.pairedImage, options: options)
        }, completionHandler: { (success, error) in
            if error != nil {
                print(error as Any)
            }
            completion(success)
        })
    }
    
    /// Generates a key photo (still image) from a video.
    ///
    /// - Parameter videoURL: The URL of the video file.
    /// - Returns: The file URL of the extracted JPEG image, or nil if extraction fails
    ///
    private func generateKeyPhoto(from videoURL: URL) -> URL? {
        var percent:Float = 0.5
        let videoAsset = AVURLAsset(url: videoURL)
        if let stillImageTime = videoAsset.stillImageTime() {
            percent = Float(stillImageTime.value) / Float(videoAsset.duration.value)
        }
        guard let imageFrame = videoAsset.getAssetFrame(percent: percent) else { return nil }
        guard let jpegData = imageFrame.jpegData(compressionQuality: 1.0) else { return nil }
        let url = assetDirectory.appendingPathComponent(LivePhotoManager.keyPhotoKey).appendingPathExtension("jpg")
        do {
            try? jpegData.write(to: url)
            return url
        }
    }
    
    /// Internal method that generates a `PHLivePhoto` by injecting asset identifiers into the image and video files.
    ///
    /// - Parameters:
    ///   - imageURL: Optional image file URL.
    ///   - videoURL: Video file URL.
    ///   - progress: Progress callback.
    ///   - completion: Completion callback with the final `PHLivePhoto` and resources.
    ///
    private func generatePHLivePhoto(
        from imageURL: URL?,
        videoURL: URL,
        progress: @escaping (CGFloat) -> Void,
        completion: @escaping (PHLivePhoto?, LivePhotoResources?) -> Void
    ) {
        guard let cacheDirectory = cacheDirectory else {
            DispatchQueue.main.async {
                completion(nil, nil)
            }
            return
        }
        let assetIdentifier = UUID().uuidString
        let _keyPhotoURL = imageURL ?? generateKeyPhoto(from: videoURL)
        guard let keyPhotoURL = _keyPhotoURL,
              let pairedImageURL = addAssetID(
                assetIdentifier,
                toImage: keyPhotoURL,
                saveTo: cacheDirectory.appendingPathComponent(assetIdentifier).appendingPathExtension("jpg")
              ) else {
            DispatchQueue.main.async {
                completion(nil, nil)
            }
            return
        }
        addAssetID(
            assetIdentifier,
            toVideo: videoURL,
            saveTo: cacheDirectory.appendingPathComponent(assetIdentifier).appendingPathExtension("mov"),
            progress: progress
        ) { _videoURL in
            if let pairedVideoURL = _videoURL {
                _ = PHLivePhoto.request(
                    withResourceFileURLs: [pairedVideoURL, pairedImageURL],
                    placeholderImage: nil,
                    targetSize: CGSize.zero,
                    contentMode: PHImageContentMode.aspectFit,
                    resultHandler: { (livePhoto: PHLivePhoto?, info: [AnyHashable : Any]) -> Void in
                    if let isDegraded = info[PHLivePhotoInfoIsDegradedKey] as? Bool, isDegraded {
                        return
                    }
                    DispatchQueue.main.async {
                        completion(livePhoto, (pairedImageURL, pairedVideoURL))
                    }
                })
            } else {
                DispatchQueue.main.async {
                    completion(nil, nil)
                }
            }
        }
    }
    
    /// Extracts the key photo and paired video resources from a given `PHLivePhoto` and saves them as files in the specified directory.
    /// - Parameters:
    ///   - livePhoto: The `PHLivePhoto` instance from which resources will be extracted.
    ///   - directoryURL: The destination directory where the key photo and video will be saved.
    ///   - completion: A closure that is called once the resources are successfully extracted and saved. It provides URLs for the key photo and video, or `nil` if extraction fails.
    ///
    private func extractResources(
        from livePhoto: PHLivePhoto,
        to directoryURL: URL,
        completion: @escaping (LivePhotoResources?) -> Void
    ) {
        let assetResources = PHAssetResource.assetResources(for: livePhoto)
        let group = DispatchGroup()
        var keyPhotoURL: URL?
        var videoURL: URL?
        for resource in assetResources {
            let buffer = NSMutableData()
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            group.enter()
            PHAssetResourceManager.default().requestData(for: resource, options: options, dataReceivedHandler: { (data) in
                buffer.append(data)
            }) { (error) in
                if error == nil {
                    if resource.type == .pairedVideo {
                        let videoUrl = directoryURL.appendingPathComponent(LivePhotoManager.videoKey)
                        videoURL = self.saveAssetResource(resource, to: videoUrl, resourceData: buffer as Data)
                    } else {
                        let photoUrl = directoryURL.appendingPathComponent(LivePhotoManager.keyPhotoKey)
                        keyPhotoURL = self.saveAssetResource(resource, to: photoUrl, resourceData: buffer as Data)
                    }
                } else {
                    print(error as Any)
                }
                group.leave()
            }
        }
        group.notify(queue: DispatchQueue.main) {
            guard let pairedPhotoURL = keyPhotoURL, let pairedVideoURL = videoURL else {
                completion(nil)
                return
            }
            completion((pairedPhotoURL, pairedVideoURL))
        }
    }
    
    /// Saves a given `PHAssetResource` data to a specified file URL with the appropriate file extension.
    /// - Parameters:
    ///   - resource: The asset resource to be saved.
    ///   - fileUrl: The base file URL where the resource will be written.
    ///   - resourceData: The binary data of the resource.
    /// - Returns: The final file URL if the write operation is successful, otherwise `nil`.
    ///
    private func saveAssetResource(_ resource: PHAssetResource, to fileUrl: URL, resourceData: Data) -> URL? {
        let fileExtension = UTTypeCopyPreferredTagWithClass(
            resource.uniformTypeIdentifier as CFString,
            kUTTagClassFilenameExtension
        )?.takeRetainedValue()
        
        guard let ext = fileExtension else {
            return nil
        }
        
        let fileUrl = fileUrl.appendingPathExtension(ext as String)
        
        do {
            try resourceData.write(to: fileUrl, options: [Data.WritingOptions.atomic])
        } catch {
            print("Could not save resource \(resource) to filepath \(String(describing: fileUrl))")
            return nil
        }
        
        return fileUrl
    }
    
    /// Adds a given asset identifier to the metadata of a JPEG image and saves the updated image to a new location.
    /// - Parameters:
    ///   - assetIdentifier: A unique identifier string to embed in the image metadata.
    ///   - imageURL: The URL of the image whose metadata needs to be updated.
    ///   - destinationURL: The location where the updated image will be saved.
    /// - Returns: The destination URL where the image was saved, or `nil` if the operation failed.
    ///
    func addAssetID(_ assetIdentifier: String, toImage imageURL: URL, saveTo destinationURL: URL) -> URL? {
        guard let imageDestination = CGImageDestinationCreateWithURL(destinationURL as CFURL, kUTTypeJPEG, 1, nil),
              let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, nil),
                var imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [AnyHashable : Any] else { return nil }
        let assetIdentifierKey = "17"
        let assetIdentifierInfo = [assetIdentifierKey : assetIdentifier]
        imageProperties[kCGImagePropertyMakerAppleDictionary] = assetIdentifierInfo
        CGImageDestinationAddImage(imageDestination, imageRef, imageProperties as CFDictionary)
        CGImageDestinationFinalize(imageDestination)
        return destinationURL
    }
    
    var audioReader: AVAssetReader?
    var videoReader: AVAssetReader?
    var assetWriter: AVAssetWriter?
    
    /// Adds a given asset identifier to the metadata of a video and saves the updated video to a new location, including audio and video tracks.
    /// Progress updates are provided through a closure that tracks the completion percentage during the writing process.
    /// - Parameters:
    ///   - assetIdentifier: A unique identifier string to embed in the video metadata.
    ///   - videoURL: The URL of the video to which the asset identifier will be added.
    ///   - destinationURL: The location where the updated video will be saved.
    ///   - progress: A closure that receives a `CGFloat` value representing the progress (from 0.0 to 1.0) of the video processing.
    ///   - completion: A closure that is called once the video is processed, providing the final destination URL, or `nil` if the process fails.
    ///
    func addAssetID(
        _ assetIdentifier: String,
        toVideo videoURL: URL,
        saveTo destinationURL: URL,
        progress: @escaping (CGFloat) -> Void,
        completion: @escaping (URL?) -> Void) {
        
        var audioWriterInput: AVAssetWriterInput?
        var audioReaderOutput: AVAssetReaderOutput?
        let videoAsset = AVURLAsset(url: videoURL)
        let frameCount = videoAsset.countFrames(exact: false)
        guard let videoTrack = videoAsset.tracks(withMediaType: .video).first else {
            completion(nil)
            return
        }
        do {
            // Create the Asset Writer
            assetWriter = try AVAssetWriter(outputURL: destinationURL, fileType: .mov)
            // Create Video Reader Output
            videoReader = try AVAssetReader(asset: videoAsset)
            let videoReaderSettings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)]
            let videoReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderSettings)
            videoReader?.add(videoReaderOutput)
            // Create Video Writer Input
            let videoWriterInput = AVAssetWriterInput(
                mediaType: .video,
                outputSettings: [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: videoTrack.naturalSize.width,
                    AVVideoHeightKey: videoTrack.naturalSize.height
                ]
            )
            videoWriterInput.transform = videoTrack.preferredTransform
            videoWriterInput.expectsMediaDataInRealTime = true
            assetWriter?.add(videoWriterInput)
            // Create Audio Reader Output & Writer Input
            if let audioTrack = videoAsset.tracks(withMediaType: .audio).first {
                do {
                    let _audioReader = try AVAssetReader(asset: videoAsset)
                    let _audioReaderOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)
                    _audioReader.add(_audioReaderOutput)
                    audioReader = _audioReader
                    audioReaderOutput = _audioReaderOutput
                    let _audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
                    _audioWriterInput.expectsMediaDataInRealTime = false
                    assetWriter?.add(_audioWriterInput)
                    audioWriterInput = _audioWriterInput
                } catch {
                    print(error)
                }
            }
            // Create necessary identifier metadata and still image time metadata
            let assetIdentifierMetadata = metadataForAssetID(assetIdentifier)
            let stillImageTimeMetadataAdapter = createMetadataAdaptorForStillImageTime()
            assetWriter?.metadata = [assetIdentifierMetadata]
            assetWriter?.add(stillImageTimeMetadataAdapter.assetWriterInput)
            // Start the Asset Writer
            assetWriter?.startWriting()
            assetWriter?.startSession(atSourceTime: CMTime.zero)
            // Add still image metadata
            let _stillImagePercent: Float = 0.5
            stillImageTimeMetadataAdapter.append(
                AVTimedMetadataGroup(
                    items: [metadataItemForStillImageTime()],
                    timeRange: videoAsset.makeStillImageTimeRange(percent: _stillImagePercent, inFrameCount: frameCount)
                )
            )
            // For end of writing / progress
            var writingVideoFinished = false
            var writingAudioFinished = false
            var currentFrameCount = 0
            func didCompleteWriting() {
                guard writingAudioFinished && writingVideoFinished else { return }
                assetWriter?.finishWriting {
                    if self.assetWriter?.status == .completed {
                        completion(destinationURL)
                    } else {
                        completion(nil)
                    }
                }
            }
            // Start writing video
            if videoReader?.startReading() ?? false {
                videoWriterInput.requestMediaDataWhenReady(on: DispatchQueue(label: "videoWriterInputQueue")) {
                    while videoWriterInput.isReadyForMoreMediaData {
                        if let sampleBuffer = videoReaderOutput.copyNextSampleBuffer()  {
                            currentFrameCount += 1
                            let percent:CGFloat = CGFloat(currentFrameCount)/CGFloat(frameCount)
                            progress(percent)
                            if !videoWriterInput.append(sampleBuffer) {
                                print("Cannot write: \(String(describing: self.assetWriter?.error?.localizedDescription))")
                                self.videoReader?.cancelReading()
                            }
                        } else {
                            videoWriterInput.markAsFinished()
                            writingVideoFinished = true
                            didCompleteWriting()
                        }
                    }
                }
            } else {
                writingVideoFinished = true
                didCompleteWriting()
            }
            // Start writing audio
            if audioReader?.startReading() ?? false {
                audioWriterInput?.requestMediaDataWhenReady(on: DispatchQueue(label: "audioWriterInputQueue")) {
                    while audioWriterInput?.isReadyForMoreMediaData ?? false {
                        guard let sampleBuffer = audioReaderOutput?.copyNextSampleBuffer() else {
                            audioWriterInput?.markAsFinished()
                            writingAudioFinished = true
                            didCompleteWriting()
                            return
                        }
                        audioWriterInput?.append(sampleBuffer)
                    }
                }
            } else {
                writingAudioFinished = true
                didCompleteWriting()
            }
        } catch {
            print(error)
            completion(nil)
        }
    }
    
    /// Creates metadata for the asset identifier to be embedded in video and audio tracks.
    /// - Parameters:
    ///   - assetIdentifier: The identifier string to embed in the metadata.
    /// - Returns: A `AVMetadataItem` containing the asset identifier metadata.
    ///
    private func metadataForAssetID(_ assetIdentifier: String) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        let keyContentIdentifier =  "com.apple.quicktime.content.identifier"
        let keySpaceQuickTimeMetadata = "mdta"
        item.key = keyContentIdentifier as (NSCopying & NSObjectProtocol)?
        item.keySpace = AVMetadataKeySpace(rawValue: keySpaceQuickTimeMetadata)
        item.value = assetIdentifier as (NSCopying & NSObjectProtocol)?
        item.dataType = "com.apple.metadata.datatype.UTF-8"
        return item
    }
    
    /// Creates a metadata adaptor for still image time, which is embedded in video metadata to represent the timing of a still image within the video.
    /// - Returns: An `AVAssetWriterInputMetadataAdaptor` that can be used to add still image time metadata to the video.
    ///
    private func createMetadataAdaptorForStillImageTime() -> AVAssetWriterInputMetadataAdaptor {
        let keyStillImageTime = "com.apple.quicktime.still-image-time"
        let keySpaceQuickTimeMetadata = "mdta"
        let spec : NSDictionary = [
            kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier as NSString:
            "\(keySpaceQuickTimeMetadata)/\(keyStillImageTime)",
            kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType as NSString:
            "com.apple.metadata.datatype.int8"            ]
        var desc : CMFormatDescription? = nil
        CMMetadataFormatDescriptionCreateWithMetadataSpecifications(
            allocator: kCFAllocatorDefault,
            metadataType: kCMMetadataFormatType_Boxed,
            metadataSpecifications: [spec] as CFArray,
            formatDescriptionOut: &desc
        )
        let input = AVAssetWriterInput(
            mediaType: .metadata,
            outputSettings: nil,
            sourceFormatHint: desc
        )
        return AVAssetWriterInputMetadataAdaptor(assetWriterInput: input)
    }
    
    /// Creates an `AVMetadataItem` for the still image time metadata, used to represent the time at which the still image appears in the video.
    /// - Returns: An `AVMetadataItem` with still image time metadata.
    ///
    private func metadataItemForStillImageTime() -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        let keyStillImageTime = "com.apple.quicktime.still-image-time"
        let keySpaceQuickTimeMetadata = "mdta"
        item.key = keyStillImageTime as (NSCopying & NSObjectProtocol)?
        item.keySpace = AVMetadataKeySpace(rawValue: keySpaceQuickTimeMetadata)
        item.value = 0 as (NSCopying & NSObjectProtocol)?
        item.dataType = "com.apple.metadata.datatype.int8"
        return item
    }
    
}

fileprivate extension AVAsset {
    
    /// Calculates the total number of frames in the video asset.
    /// - Parameter exact: A boolean flag indicating whether to calculate the exact frame count (`true`) or estimate based on the video duration and frame rate (`false`).
    /// - Returns: The total number of frames in the video. If `exact` is `true`, it counts frames by reading the asset's sample buffers. Otherwise, it estimates the frame count based on the asset's duration and frame rate.
    ///
    func countFrames(exact: Bool) -> Int {
        var frameCount = 0
        if let videoReader = try? AVAssetReader(asset: self)  {
            if let videoTrack = self.tracks(withMediaType: .video).first {
                frameCount = Int(CMTimeGetSeconds(self.duration) * Float64(videoTrack.nominalFrameRate))
                if exact {
                    
                    frameCount = 0
                    
                    let videoReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: nil)
                    videoReader.add(videoReaderOutput)
                    
                    videoReader.startReading()
                    
                    // count frames
                    while true {
                        let sampleBuffer = videoReaderOutput.copyNextSampleBuffer()
                        if sampleBuffer == nil {
                            break
                        }
                        frameCount += 1
                    }
                    
                    videoReader.cancelReading()
                }
            }
        }
        return frameCount
    }
    
    /// Extracts the still image time from the asset's metadata, if available.
    /// - Returns: A `CMTime` representing the still image time, or `nil` if no still image time is found in the metadata.
    ///
    func stillImageTime() -> CMTime?  {
        var stillTime:CMTime? = nil
        
        if let videoReader = try? AVAssetReader(asset: self)  {
            
            if let metadataTrack = self.tracks(withMediaType: .metadata).first {
                
                let videoReaderOutput = AVAssetReaderTrackOutput(track: metadataTrack, outputSettings: nil)
                
                videoReader.add(videoReaderOutput)
                
                videoReader.startReading()
                
                let keyStillImageTime = "com.apple.quicktime.still-image-time"
                let keySpaceQuickTimeMetadata = "mdta"
                
                var found = false
                
                while found == false {
                    if let sampleBuffer = videoReaderOutput.copyNextSampleBuffer() {
                        if CMSampleBufferGetNumSamples(sampleBuffer) != 0 {
                            let group = AVTimedMetadataGroup(sampleBuffer: sampleBuffer)
                            for item in group?.items ?? [] {
                                if item.key as? String == keyStillImageTime && item.keySpace!.rawValue == keySpaceQuickTimeMetadata {
                                    stillTime = group?.timeRange.start
                                    //print("stillImageTime = \(CMTimeGetSeconds(stillTime!))")
                                    found = true
                                    break
                                }
                            }
                        }
                    }
                    else {
                        break;
                    }
                }
                videoReader.cancelReading()
            }
        }
        return stillTime
    }
    
    /// Creates a `CMTimeRange` for the still image based on a given percentage of the total video duration.
    /// - Parameters:
    ///   - percent: A float representing the percentage of the video duration at which the still image should be taken (e.g., `0.5` for the middle of the video).
    ///   - inFrameCount: The total number of frames to use for the calculation. If `0`, the method will compute the frame count from the video.
    /// - Returns: A `CMTimeRange` representing the time range for the still image within the video.
    ///
    func makeStillImageTimeRange(percent: Float, inFrameCount:Int = 0) -> CMTimeRange {
        var time = self.duration
        
        var frameCount = inFrameCount
        
        if frameCount == 0 {
            frameCount = self.countFrames(exact: true)
        }
        
        let frameDuration = Int64(Float(time.value) / Float(frameCount))
        
        time.value = Int64(Float(time.value) * percent)
        
        //print("stillImageTime = \(CMTimeGetSeconds(time))")
        
        return CMTimeRangeMake(start: time, duration: CMTimeMake(value: frameDuration, timescale: time.timescale))
    }
    
    /// Generates a still image from the asset at a specified percentage of the video's duration.
    /// - Parameter percent: A float representing the percentage of the video duration at which the still image should be taken (e.g., `0.5` for the middle of the video).
    /// - Returns: A `UIImage` generated from the video at the specified percentage of the video duration, or `nil` if the image generation fails.
    ///
    func getAssetFrame(percent: Float) -> UIImage?
    {
        
        let imageGenerator = AVAssetImageGenerator(asset: self)
        imageGenerator.appliesPreferredTrackTransform = true
        
        imageGenerator.requestedTimeToleranceAfter = CMTimeMake(value: 1, timescale: 100)
        imageGenerator.requestedTimeToleranceBefore = CMTimeMake(value: 1, timescale: 100)
        
        var time = self.duration
        
        time.value = Int64(Float(time.value) * percent)
        
        do {
            var actualTime = CMTime.zero
            let imageRef = try imageGenerator.copyCGImage(at: time, actualTime:&actualTime)
            
            let img = UIImage(cgImage: imageRef)
            
            return img
        }
        catch let error as NSError
        {
            print("Image generation failed with error \(error)")
            return nil
        }
    }
}
