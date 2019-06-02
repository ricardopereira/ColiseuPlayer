//
// ColiseuPlayer.swift
// Coliseu
//
// Copyright (c) 2014 Ricardo Pereira (http://ricardopereira.eu)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import AVFoundation
import MediaPlayer

/// A set of methods implemented by the delegate of a audio player to handle remote control event.
/// The methods of this protocol are all optional.
@objc public protocol ColiseuPlayerDelegate: class
{
    /// Tells the delegate that play is triggered from remote control.
    ///
    /// - Parameter player: The audio player object informing the delegate of this event.
    @objc optional func audioPlayerDidReceiveRemoteControlPlayEvent(_ player: ColiseuPlayer)

    /// Tells the delegate that pause is triggered from remote control.
    ///
    /// - Parameter player: The audio player object informing the delegate of this event.
    @objc optional func audioPlayerDidReceiveRemoteControlPauseEvent(_ player: ColiseuPlayer)

    /// Tells the delegate that previous track is triggered from remote control.
    ///
    /// - Parameter player: The audio player object informing the delegate of this event.
    @objc optional func audioPlayerDidReceiveRemoteControlPreviousTrackEvent(_ player: ColiseuPlayer)

    /// Tells the delegate that next track is triggered from remote control.
    ///
    /// - Parameter player: The audio player object informing the delegate of this event.
    @objc optional func audioPlayerDidReceiveRemoteControlNextTrackEvent(_ player: ColiseuPlayer)

    /// Tells the delegate that begin seeking backward is triggered from remote control.
    ///
    /// - Parameter player: The audio player object informing the delegate of this event.
    @objc optional func audioPlayerDidReceiveRemoteControlBeginSeekingBackwardEvent(_ player: ColiseuPlayer)

    /// Tells the delegate that seeking backward ended is triggered from remote control.
    ///
    /// - Parameter player: The audio player object informing the delegate of this event.
    @objc optional func audioPlayerDidReceiveRemoteControlEndSeekingBackwardEvent(_ player: ColiseuPlayer)

    /// Tells the delegate that begin seeking forward is triggered from remote control.
    ///
    /// - Parameter player: The audio player object informing the delegate of this event.
    @objc optional func audioPlayerDidReceiveRemoteControlBeginSeekingForwardEvent(_ player: ColiseuPlayer)

    /// Tells the delegate that seeking forward ended is triggered from remote control.
    ///
    /// - Parameter player: The audio player object informing the delegate of this event.
    @objc optional func audioPlayerDidReceiveRemoteControlEndSeekingForwardEvent(_ player: ColiseuPlayer)

    /// Tells the delegate that an audio has finished playing.
    ///
    /// The delegate will ALSO be told if the player is stopped due to an interruption.
    ///
    /// - Parameter player: The audio player object informing the delegate of this event.
    @objc optional func audioPlayerDidFinishPlaying(_ player: ColiseuPlayer, successfully flag: Bool)

    /// Tells the delegate that an audio has finished playing and will begin to play a new audio.
    ///
    /// The delegate will NOT be told if the player is stopped due to an interruption.
    ///
    /// - Parameter player: The audio player object informing the delegate of this event.
    @objc optional func audioPlayerDidFinishPlayingSuccessfullyAndWillBeginPlaying(_ player: ColiseuPlayer)
}

/// The methods adopted by the object you use to manage behaviour for a audio player.
public protocol ColiseuPlayerDataSource: class
{
    /// Asks the datasource to determine if audio is not going to repeat, repeat once or always repeat.
    ///
    /// - Parameter player: The audio player object requesting this information.
    ///
    /// - Returns: The repeat enum for the audio player.
    func audioRepeatType(in player: ColiseuPlayer) -> ColiseuPlayerRepeat

    /// Asks the datasource to determine if audio list is shuffled.
    ///
    /// - Parameter player: The audio player object requesting this information.
    ///
    /// - Returns: true to tell the audio player to shuffle the playlist, false to tell the audio player to not shuffle the playlist.
    func audioWillShuffle(in player: ColiseuPlayer) -> Bool
}

/// Specifies the repeat type of an audio player.
public enum ColiseuPlayerRepeat: Int
{
    case none = 0, one, all
}

/// An audio player engine, to make it mockable by test
internal class ColiseuPlayerEngine
{
    func initAudioPlayer(url: URL) -> AVAudioPlayer?
    {
        do {
            return try AVAudioPlayer(contentsOf: url)
        }
        catch let error {
            print("AVAudioPlayer error occurred:\n \(error)")
        }
        return nil
    }
}

/// An audio player that provides playback of audio data from a file or memory.
public class ColiseuPlayer: NSObject
{
    // MARK: - Properties

    public typealias function = () -> ()

    internal var engine: ColiseuPlayerEngine
    internal var audioPlayer: AVAudioPlayer?
    internal var timer: Timer!

    // MARK: Playlist

    internal var currentSong: AudioFile?
    internal var songsList: [AudioFile]?

    // MARK: Events

    public var playerDidStart: function?
    public var playerDidPause: function?
    public var playerDidStop: function?
    private var playerWillRepeat: Bool?

    // MARK: DataSource

    /// The object that acts as the data source of the audio player.
    public weak var dataSource: ColiseuPlayerDataSource?
    {
        willSet {
            if let responder = newValue as? UIResponder {
                responder.becomeFirstResponder()
            }
        }
    }

    // MARK: Delegate

    /// The object that acts as the delegate of the audio player.
    public weak var delegate: ColiseuPlayerDelegate?

    // MARK: Status

    /// A Boolean value that indicates whether the audio player is playing first song (true) or not (false).
    public var isFirstSong: Bool
    {
        if let currentSong = self.currentSong, currentSong.index == 0 {
            return true
        }
        return false
    }

    /// A Boolean value that indicates whether the audio player is playing last song (true) or not (false).
    public var isLastSong: Bool
    {
        if let currentSong = self.currentSong, let songsList = self.songsList, currentSong.index + 1 == songsList.count {
            return true
        }
        return false
    }

    /// A Boolean value that indicates whether the audio player is playing (true) or not (false).
    public var isPlaying: Bool
    {
        if let audioPlayer = self.audioPlayer {
            return audioPlayer.isPlaying
        }
        return false
    }

    private var isSongListValid: Bool
    {
        if let songsList = self.songsList, songsList.count > 0 {
            return true
        }
        return false
    }

    // MARK: - Init

    public override init()
    {
        // Inherited
        self.engine = ColiseuPlayerEngine()
        super.init()
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

    deinit
    {
        UIApplication.shared.endReceivingRemoteControlEvents()
        if let responder = self.dataSource as? UIResponder {
            responder.resignFirstResponder()
        }
    }

    // MARK: - Session

    /// Activates your app’s audio session using the specified options.
    public func startSession()
    {
        do {
            if #available(iOS 10.0, *) {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default)
            }
            else {
                AVAudioSession.sharedInstance().perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.playback)
            }
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch let error {
            print("AVAudioSession error occurred:\n\(error)")
        }
    }

    /// Deactivates your app’s audio session using the specified options.
    public func stopSession()
    {
        do {
            if #available(iOS 10.0, *) {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient, mode: AVAudioSession.Mode.default)
            }
            else {
                AVAudioSession.sharedInstance().perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.ambient)
            }
            try AVAudioSession.sharedInstance().setActive(false)
        }
        catch let error {
            print("AVAudioSession error occurred:\n\(error)")
        }
    }

    internal func remoteControlInfo(_ song: AudioFile)
    {
        var title: String = "Coliseu"
        if let bundleName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
            title = bundleName
        }
        // ? - Seeking test
        //let time = self.audioPlayer!.currentTime
        //self.audioPlayer!.currentTime = time + 30 //Seconds

        //slider.maximumValue = CMTimeGetSeconds([player duration])
        //slider.value = CMTimeGetSeconds(player.currentTime)
        //player.currentTime = CMTimeMakeWithSeconds((int)slider.value,1)

        // Remote Control info - ?
        var songInfo = [MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: title,
            //MPNowPlayingInfoPropertyElapsedPlaybackTime: time + 30,
            MPMediaItemPropertyPlaybackDuration: self.audioPlayer!.duration] as [String : AnyObject]

        if let artwork = song.artwork {
            if #available(iOS 10.0, *) {
                songInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artwork.size, requestHandler: { (size) -> UIImage in
                    return artwork
                })
            }
            else {
                songInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: artwork)
            }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = songInfo
    }

    private func prepareAudio(_ index: Int) -> Bool
    {
        guard let songs = self.songsList, (index >= 0 && index < songs.count) else { return false }
        prepareAudio(songs[index], index)
        return true
    }

    private func prepareAudio(_ song: AudioFile, _ index: Int)
    {
        // Keep alive audio at background
        if let _ = song.path {
            self.currentSong = song
            song.index = index
        }
        else {
            self.currentSong = nil
            return
        }

        if let path = song.path {
            self.audioPlayer = self.engine.initAudioPlayer(url: path)
        }
        self.audioPlayer!.delegate = self
        self.audioPlayer!.prepareToPlay()

        remoteControlInfo(song)

        // ?
        song.duration = self.audioPlayer!.duration
    }

    // MARK: - Commands

    /// Plays sound asynchronously from song list.
    public func playSong()
    {
        // Verify if has a valid playlist to play
        if !isSongListValid {
            return
        }
        // Check the didStart event
        if let event = self.playerDidStart {
            event()
        }
        self.audioPlayer!.play()
    }

    /// Plays sound asynchronously from song list.
    ///
    /// - Parameters:
    ///   - index: The index of song list that audio player will play from.
    ///   - songsList: The song list of the audio player.
    public func playSong(index: Int, songsList: [AudioFile])
    {
        self.songsList = songsList
        if self.dataSource?.audioWillShuffle(in: self) == true {
            self.songsList?.shuffle()
        }
        // Prepare core audio
        if prepareAudio(index) {
            // Play current song
            playSong()
        }
    }

    /// Plays sound asynchronously from song list.
    ///
    /// - Parameter index: The index of sing list that audio player will play from.
    public func playSong(index: Int)
    {
        // Verify if has a valid playlist to play
        if !isSongListValid {
            return
        }
        // Prepare core audio
        if prepareAudio(index) {
            // Play current song
            playSong()
        }
    }

    /// Pauses playback; sound remains ready to resume playback from where it left off.
    public func pauseSong()
    {
        if self.isPlaying {
            self.audioPlayer!.pause()
            if let event = self.playerDidPause {
                event()
            }
        }
    }

    /// Stops playback and undoes the setup needed for playback.
    public func stopSong()
    {
        if self.audioPlayer == nil || !self.isPlaying {
            return
        }

        self.audioPlayer!.stop()
        if let event = self.playerDidStop {
            event()
        }
        if let current = self.currentSong {
            prepareAudio(current, current.index)
        }
    }

    /// Plays next sound asynchronously from song list.
    ///
    /// - Parameter stopIfInvalid: true to tell the audio player to stop, false to tell the audio player not to stop.
    public func playNextSong(stopIfInvalid: Bool = false)
    {
        if let songs = self.songsList, let song = self.currentSong {
            var index = song.index

            // Next song
            index += 1

            if index > songs.count - 1 {
                if stopIfInvalid {
                    stopSong()
                }
                return
            }

            playSong(index: index)
        }
    }

    /// Plays previous sound asynchronously from song list.
    public func playPreviousSong()
    {
        if let _ = self.songsList, let song = self.currentSong {
            var index = song.index

            // Previous song
            index -= 1

            if index < 0 {
                return
            }

            playSong(index: index)
        }
    }

    // MARK: - ColiseuPlayerDelegate

    /// Tells the object when a remote-control event is received.
    ///
    /// - Parameter event: An event object encapsulating a remote-control command. Remote-control events have a type of UIEvent.EventType.remoteControl.
    public func didReceiveRemoteControl(event: UIEvent?)
    {
        guard let event = event, event.type == UIEvent.EventType.remoteControl else { return }
        switch event.subtype {
        case UIEvent.EventSubtype.remoteControlPlay:
            playSong()
            self.delegate?.audioPlayerDidReceiveRemoteControlPlayEvent?(self)
        case UIEvent.EventSubtype.remoteControlPause:
            pauseSong()
            self.delegate?.audioPlayerDidReceiveRemoteControlPauseEvent?(self)
        case UIEvent.EventSubtype.remoteControlPreviousTrack:
            playPreviousSong()
            self.delegate?.audioPlayerDidReceiveRemoteControlPreviousTrackEvent?(self)
        case UIEvent.EventSubtype.remoteControlNextTrack:
            playNextSong(stopIfInvalid: true)
            self.delegate?.audioPlayerDidReceiveRemoteControlNextTrackEvent?(self)
        case UIEvent.EventSubtype.remoteControlBeginSeekingBackward:
            self.delegate?.audioPlayerDidReceiveRemoteControlBeginSeekingBackwardEvent?(self)
        case UIEvent.EventSubtype.remoteControlEndSeekingBackward:
            self.delegate?.audioPlayerDidReceiveRemoteControlEndSeekingBackwardEvent?(self)
        case UIEvent.EventSubtype.remoteControlBeginSeekingForward:
            self.delegate?.audioPlayerDidReceiveRemoteControlBeginSeekingForwardEvent?(self)
        case UIEvent.EventSubtype.remoteControlEndSeekingForward:
            self.delegate?.audioPlayerDidReceiveRemoteControlEndSeekingForwardEvent?(self)
        default:
            break
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension ColiseuPlayer: AVAudioPlayerDelegate
{
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
    {
        if !flag {
            self.delegate?.audioPlayerDidFinishPlaying?(self, successfully: flag)
            return
        }
        playNextSong(stopIfInvalid: true)
        if let repeatType = self.dataSource?.audioRepeatType(in: self), !self.isPlaying {
            switch repeatType {
            case .none:
                self.playerWillRepeat = false
            case .one:
                switch self.playerWillRepeat {
                case true?:
                    self.playerWillRepeat = false
                default:
                    self.playerWillRepeat = true
                    playSong(index: 0)
                }
            case .all:
                self.playerWillRepeat = true
                playSong(index: 0)
            }
        }
        if self.isPlaying {
            self.delegate?.audioPlayerDidFinishPlayingSuccessfullyAndWillBeginPlaying?(self)
            return
        }
        self.delegate?.audioPlayerDidFinishPlaying?(self, successfully: flag)
    }
}

// MARK: - Helper

private extension Array
{
    // MARK: Shuffle Array

    mutating func shuffle()
    {
        if count < 2 { return }
        for i in 0..<(count - 1) {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            guard i != j else { continue }
            swapAt(i, j)
        }
    }
}
