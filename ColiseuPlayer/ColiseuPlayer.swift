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

private protocol AudioPlayerProtocol: AVAudioPlayerDelegate
{
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
}

/// A protocol for delegates of ColiseuPlayer
@objc public protocol ColiseuPlayerDelegate: class
{
    /// Tells the delegate that play button is clicked from remote control.
    ///
    /// - Parameters:
    ///   - controller: The instance object of ColiseuPlayer
    ///   - eventSubtype: the instance object of EventSubtype for UIEvent
    @objc optional func audioPlayer(_ controller: ColiseuPlayer, didReceiveRemoteControlPlayEvent eventSubtype: UIEvent.EventSubtype)

    /// Tells the delegate that pause button is clicked from remote control.
    ///
    /// - Parameters:
    ///   - controller: The instance object of ColiseuPlayer
    ///   - eventSubtype: the instance object of EventSubtype for UIEvent
    @objc optional func audioPlayer(_ controller: ColiseuPlayer, didReceiveRemoteControlPauseEvent eventSubtype: UIEvent.EventSubtype)

    /// Tells the delegate that rewind button is clicked from remote control.
    ///
    /// - Parameters:
    ///   - controller: The instance object of ColiseuPlayer
    ///   - eventSubtype: the instance object of EventSubtype for UIEvent
    @objc optional func audioPlayer(_ controller: ColiseuPlayer, didReceiveRemoteControlPreviousTrackEvent eventSubtype: UIEvent.EventSubtype)

    /// Tells the delegate that fast forward button is clicked from remote control.
    ///
    /// - Parameters:
    ///   - controller: The instance object of ColiseuPlayer
    ///   - eventSubtype: the instance object of EventSubtype for UIEvent
    @objc optional func audioPlayer(_ controller: ColiseuPlayer, didReceiveRemoteControlNextTrackEvent eventSubtype: UIEvent.EventSubtype)

    /// Tells the delegate that it is begin seeking backward from remote control.
    ///
    /// - Parameters:
    ///   - controller: The instance object of ColiseuPlayer
    ///   - eventSubtype: the instance object of EventSubtype for UIEvent
    @objc optional func audioPlayer(_ controller: ColiseuPlayer, didReceiveRemoteControlBeginSeekingBackwardEvent eventSubtype: UIEvent.EventSubtype)

    /// Tells the delegate that it is seeking backward ended from remote control.
    ///
    /// - Parameters:
    ///   - controller: The instance object of ColiseuPlayer
    ///   - eventSubtype: the instance object of EventSubtype for UIEvent
    @objc optional func audioPlayer(_ controller: ColiseuPlayer, didReceiveRemoteControlEndSeekingBackwardEvent eventSubtype: UIEvent.EventSubtype)

    /// Tells the delegate that it is begin seeking forward from remote control.
    ///
    /// - Parameters:
    ///   - controller: The instance object of ColiseuPlayer
    ///   - eventSubtype: the instance object of EventSubtype for UIEvent
    @objc optional func audioPlayer(_ controller: ColiseuPlayer, didReceiveRemoteControlBeginSeekingForwardEvent eventSubtype: UIEvent.EventSubtype)

    /// Tells the delegate that it is seeking forward ended from remote control.
    ///
    /// - Parameters:
    ///   - controller: The instance object of ColiseuPlayer
    ///   - eventSubtype: the instance object of EventSubtype for UIEvent
    @objc optional func audioPlayer(_ controller: ColiseuPlayer, didReceiveRemoteControlEndSeekingForwardEvent eventSubtype: UIEvent.EventSubtype)

    /// Tells the delegate that an audio has finished playing.
    ///
    /// The delegate will ALSO be told if the player is stopped due to an interruption.
    ///
    /// - Parameters:
    ///   - controller: The instance object of ColiseuPlayer
    ///   - flag: the indicator if audio ended successfully or not
    @objc optional func audioPlayer(_ controller: ColiseuPlayer, didFinishPlayingSuccessfully flag: Bool)

    /// Tells the delegate that an audio has finished playing and will begin to play a new audio.
    ///
    /// The delegate will NOT be told if the player is stopped due to an interruption.
    ///
    /// - Parameters:
    ///   - controller: The instance object of ColiseuPlayer
    @objc optional func audioPlayerDidFinishPlayingSuccessfullyAndWillBeginPlaying(_ controller: ColiseuPlayer)
}

/// A protocol for datasource of ColiseuPlayer
public protocol ColiseuPlayerDataSource: class
{
    /// Asks the datasource to determine if audio is not going to repeat, repeat once or always repeat.
    ///
    /// - Parameters:
    ///   - controller: The instance object of ColiseuPlayer
    ///
    /// - Returns: An enum of ColiseuPlayerRepeat.
    func audioRepeatTypeInAudioPlayer(_ controller: ColiseuPlayer) -> ColiseuPlayerRepeat

    /// Asks the datasource to determine if audio list is shuffled.
    ///
    /// - Parameters:
    ///   - controller: The instance object of ColiseuPlayer
    ///
    /// - Returns: A boolean to indicate audio will shuffle or not
    func audioWillShuffleInAudioPlayer(_ controller: ColiseuPlayer) -> Bool
}

/// An enum for repeat type of ColiseuPlayer
public enum ColiseuPlayerRepeat: Int
{
    case none = 0, one, all
}

public class ColiseuPlayer: NSObject
{
    public typealias function = () -> ()

    internal var audioPlayer: AVAudioPlayer?
    internal var timer: Timer!

    // MARK: Playlist

    internal var currentSong: AudioFile?
    internal var songsList: [AudioFile]?

    // MARK: Events

    public var playerDidStart: function?
    public var playerDidStop: function?
    private var playerWillRepeat: Bool?

    // MARK: DataSource

    public weak var dataSource: ColiseuPlayerDataSource?
    {
        willSet {
            if let responder = newValue as? UIResponder {
                responder.becomeFirstResponder()
            }
        }
    }

    // MARK: Delegate

    public weak var delegate: ColiseuPlayerDelegate?

    public override init()
    {
        // Inherited
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

    public func startSession()
    {
        // Session
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

    private func prepareAudio(_ index: Int)
    {
        guard let songs = self.songsList, (index >= 0 && index < songs.count) else {
            return
        }
        prepareAudio(songs[index], index)
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

        do {
            if let path = song.path {
                self.audioPlayer = try AVAudioPlayer(contentsOf: path)
            }
        }
        catch let error {
            print("AVAudioPlayer error occurred:\n \(error)")
        }
        self.audioPlayer!.delegate = self
        self.audioPlayer!.prepareToPlay()

        remoteControlInfo(song)

        // ?
        song.duration = self.audioPlayer!.duration
    }

    private var isSongListValid: Bool
    {
        if let songsList = self.songsList, songsList.count > 0 {
            return true
        }
        return false
    }

    // MARK: Commands

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

    public func playSong(index: Int, songsList: [AudioFile])
    {
        self.songsList = songsList
        if self.dataSource?.audioWillShuffleInAudioPlayer(self) == true {
            self.songsList?.shuffle()
        }
        // Prepare core audio
        prepareAudio(index)
        // Play current song
        playSong()
    }

    public func playSong(index: Int)
    {
        // Verify if has a valid playlist to play
        if !isSongListValid {
            return
        }
        // Prepare core audio
        prepareAudio(index)
        // Play current song
        playSong()
    }

    public func pauseSong()
    {
        if isPlaying {
            self.audioPlayer!.pause()
        }
    }

    public func stopSong()
    {
        if self.audioPlayer == nil || !isPlaying {
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

    public var isPlaying: Bool
    {
        return self.audioPlayer!.isPlaying
    }

    public var isLastSong: Bool
    {
        if let currentSong = self.currentSong, let songsList = self.songsList, currentSong.index + 1 == songsList.count {
            return true
        }
        return false
    }

    public var isFirstSong: Bool
    {
        if let currentSong = self.currentSong, currentSong.index == 0 {
            return true
        }
        return false
    }

    // MARK: ColiseuPlayerDelegate

    public func remoteControlEvent(event: UIEvent)
    {
        if event.type == UIEvent.EventType.remoteControl {
            switch event.subtype {
            case UIEvent.EventSubtype.remoteControlPlay:
                playSong()
                self.delegate?.audioPlayer?(self, didReceiveRemoteControlPlayEvent: event.subtype)
            case UIEvent.EventSubtype.remoteControlPause:
                pauseSong()
                self.delegate?.audioPlayer?(self, didReceiveRemoteControlPauseEvent: event.subtype)
            case UIEvent.EventSubtype.remoteControlPreviousTrack:
                playPreviousSong()
                self.delegate?.audioPlayer?(self, didReceiveRemoteControlPreviousTrackEvent: event.subtype)
            case UIEvent.EventSubtype.remoteControlNextTrack:
                playNextSong(stopIfInvalid: true)
                self.delegate?.audioPlayer?(self, didReceiveRemoteControlNextTrackEvent: event.subtype)
            case UIEvent.EventSubtype.remoteControlBeginSeekingBackward:
                self.delegate?.audioPlayer?(self, didReceiveRemoteControlBeginSeekingBackwardEvent: event.subtype)
            case UIEvent.EventSubtype.remoteControlEndSeekingBackward:
                self.delegate?.audioPlayer?(self, didReceiveRemoteControlEndSeekingBackwardEvent: event.subtype)
            case UIEvent.EventSubtype.remoteControlBeginSeekingForward:
                self.delegate?.audioPlayer?(self, didReceiveRemoteControlBeginSeekingForwardEvent: event.subtype)
            case UIEvent.EventSubtype.remoteControlEndSeekingForward:
                self.delegate?.audioPlayer?(self, didReceiveRemoteControlEndSeekingForwardEvent: event.subtype)
            default: break
            }
        }
    }
}

// MARK: AudioPlayerProtocol

extension ColiseuPlayer: AudioPlayerProtocol
{
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
    {
        if !flag {
            self.delegate?.audioPlayer?(self, didFinishPlayingSuccessfully: flag)
            return
        }
        playNextSong(stopIfInvalid: true)
        if let repeatType = self.dataSource?.audioRepeatTypeInAudioPlayer(self), !isPlaying {
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
        if isPlaying {
            self.delegate?.audioPlayerDidFinishPlayingSuccessfullyAndWillBeginPlaying?(self)
            return
        }
        self.delegate?.audioPlayer?(self, didFinishPlayingSuccessfully: flag)
    }
}

// MARK: Shuffle Array

private extension Array
{
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
