//
//  VideoPlayerObserver.swift
//  OneVaultNewVersion
//
//  Created by Hafiz Muhammad Ali on 24/02/2025.
//

import Foundation
import Combine
import AVFoundation
import AVKit

/// A class that observes the playback status of an `AVPlayer` instance, publishing changes to whether the player is playing or paused.
/// The class uses `@Published` to allow other views or components to react to playback state changes in real-time.
/// It subscribes to changes in the `AVPlayer`'s `timeControlStatus` to track whether the player is currently playing.
///
/// - `@Published` isPlaying: A Boolean that indicates whether the video is currently playing (`true`) or paused (`false`).
/// - `private var cancellable`: Holds the subscription for observing changes in the `AVPlayer`'s time control status.
/// - `var player`: The `AVPlayer` instance being observed. Setting a new player triggers the observation of its time control status.
///
class VideoPlayerObserver: ObservableObject {
    @Published var isPlaying: Bool = false
    private var cancellable: AnyCancellable?
    
    var player: AVPlayer? {
        didSet {
            observePlayer()
        }
    }
    
    /// Observes the `AVPlayer`'s `timeControlStatus` and updates the `isPlaying` property accordingly.
    private func observePlayer() {
        cancellable = player?
            .publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.isPlaying = (status == .playing)
            }
    }
}
