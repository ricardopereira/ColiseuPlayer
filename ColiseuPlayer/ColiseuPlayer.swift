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

protocol AudioPlayerProtocol: AVAudioPlayerDelegate
{
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool)
}

/* A protocol for delegates of ColiseuPlayer */
@objc public protocol ColiseuPlayerDelegate: class
{
    /* audioPlayer:didReceiveRemoteControlPlayEvent: is called when play button is clicked from remote control. */
    @objc optional func audioPlayer(_ controller: ColiseuPlayer, didReceiveRemoteControlPlayEvent eventSubtype: UIEvent.EventSubtype)

    /* audioPlayer:didReceiveRemoteControlPauseEvent: is called when pause button is clicked from remote control. */
    @objc optional func audioPlayer(_ controller: ColiseuPlayer, didReceiveRemoteControlPauseEvent eventSubtype: UIEvent.EventSubtype)

    /* audioPlayer:didReceiveRemoteControlPreviousTrackEvent: is called when rewind button is clicked from remote control. */
    @objc optional func audioPlayer(_ controller: ColiseuPlayer, didReceiveRemoteControlPreviousTrackEvent eventSubtype: UIEvent.EventSubtype)

    /* audioPlayer:didReceiveRemoteControlNextTrackEvent: is called when fast forward button is clicked from remote control. */
    @objc optional func audioPlayer(_ controller: ColiseuPlayer, didReceiveRemoteControlNextTrackEvent eventSubtype: UIEvent.EventSubtype)

    /* audioPlayer:didReceiveRemoteControlBeginSeekingBackwardEvent: is called when begin seeking backward from remote control. */
    @objc optional func audioPlayer(_ controller: ColiseuPlayer, didReceiveRemoteControlBeginSeekingBackwardEvent eventSubtype: UIEvent.EventSubtype)

    /* audioPlayer:didReceiveRemoteControlEndSeekingBackwardEvent: is called when seeking backward ended from remote control. */
    @objc optional func audioPlayer(_ controller: ColiseuPlayer, didReceiveRemoteControlEndSeekingBackwardEvent eventSubtype: UIEvent.EventSubtype)

    /* audioPlayer:didReceiveRemoteControlBeginSeekingForwardEvent: is called when begin seeking forward from remote control. */
    @objc optional func audioPlayer(_ controller: ColiseuPlayer, didReceiveRemoteControlBeginSeekingForwardEvent eventSubtype: UIEvent.EventSubtype)

    /* audioPlayer:didReceiveRemoteControlEndSeekingForwardEvent: is called when seeking forward ended from remote control. */
    @objc optional func audioPlayer(_ controller: ColiseuPlayer, didReceiveRemoteControlEndSeekingForwardEvent eventSubtype: UIEvent.EventSubtype)
}

/* A protocol for datasource of ColiseuPlayer */
@objc public protocol ColiseuPlayerDataSource: class
{
    // Determine whether audio is not going to repeat, repeat once or always repeat.
    @objc optional func audioRepeatTypeInAudioPlayer(_ controller: ColiseuPlayer) -> ColiseuPlayerRepeat.RawValue

    // Determine whether audio list is shuffled.
    @objc optional func audioWillShuffleInAudioPlayer(_ controller: ColiseuPlayer) -> Bool
}

/* An enum for repeat type of ColiseuPlayer */
public enum ColiseuPlayerRepeat: Int
{
    case None = 0, One, All
}

public class ColiseuPlayer: NSObject
{
    public typealias function = () -> ()

    internal var audioPlayer: AVAudioPlayer?
    internal var timer: Timer!

    // Playlist
    internal var currentSong: AudioFile?
    internal var songsList: [AudioFile]?

    // Events
    public var playerDidStart: function?
    public var playerDidStop: function?
    private var playerWillRepeat: Bool?

    // Delegate
    public weak var delegate: ColiseuPlayerDelegate? {
        willSet {
            if let responder = newValue as? UIResponder {
                responder.becomeFirstResponder()
            }
        }
    }

    // DataSource
    public weak var dataSource: ColiseuPlayerDataSource?

    public override init()
    {
        // Inherited
        super.init()
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

    deinit
    {
        UIApplication.shared.endReceivingRemoteControlEvents()
        if let responder = self.delegate as? UIResponder {
            responder.resignFirstResponder()
        }
    }

    public func startSession()
    {
        // Session
        do {
            if #available(iOS 10.0, *) {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default)
            } else {
                AVAudioSession.sharedInstance().perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.playback)
            }
        }
        catch let error as NSError {
            print("A AVAudioSession setCategory error occurred, here are the details:\n \(error)")
        }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch let error as NSError {
            print("A AVAudioSession setActive error occurred, here are the details:\n \(error)")
        }
    }

    public func stopSession() {
        do {
            if #available(iOS 10.0, *) {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient, mode: AVAudioSession.Mode.default)
            } else {
                AVAudioSession.sharedInstance().perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.ambient)
            }
        }
        catch let error as NSError {
            print("A AVAudioSession setCategory error occurred, here are the details:\n \(error)")
        }
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        }
        catch let error as NSError {
            print("A AVAudioSession setActive error occurred, here are the details:\n \(error)")
        }
    }

    internal func remoteControlInfo(song: AudioFile)
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
            songInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: artwork)
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = songInfo
    }

    private func prepareAudio(index: Int)
    {
        guard let songs = self.songsList, (index >= 0 && index < songs.count) else {
            return
        }
        prepareAudio(song: songs[index], index)
    }

    private func prepareAudio(song: AudioFile, _ index: Int)
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
            self.audioPlayer = try AVAudioPlayer(contentsOf: song.path!)
        }
        catch let error as NSError {
            print("A AVAudioPlayer contentsOfURL error occurred, here are the details:\n \(error)")
        }
        self.audioPlayer!.delegate = self
        self.audioPlayer!.prepareToPlay()

        remoteControlInfo(song: song)

        // ?
        song.duration = self.audioPlayer!.duration
    }

    private func songListIsValid() -> Bool
    {
        if self.songsList == nil || self.songsList!.count == 0 {
            return false
        }
        return true
    }

    // MARK: Commands

    public func playSong()
    {
        // Verify if has a valid playlist to play
        if !songListIsValid() {
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
        if let dataSource = self.dataSource, dataSource.audioWillShuffleInAudioPlayer?(self) == true {
            self.songsList?.shuffle()
        }
        // Prepare core audio
        prepareAudio(index: index)
        // Play current song
        playSong()
    }

    public func playSong(index: Int)
    {
        // Verify if has a valid playlist to play
        if !songListIsValid() {
            return
        }
        // Prepare core audio
        prepareAudio(index: index)
        // Play current song
        playSong()
    }

    public func pauseSong()
    {
        if self.audioPlayer!.isPlaying {
            self.audioPlayer!.pause()
        }
    }

    public func stopSong()
    {
        if self.audioPlayer == nil || !self.audioPlayer!.isPlaying {
            return
        }

        self.audioPlayer!.stop()
        if let event = self.playerDidStop {
            event()
        }
        if let current = self.currentSong {
            prepareAudio(song: current, current.index)
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

    public func isLastSong() -> Bool
    {
        if let currentSong = self.currentSong, let songsList = self.songsList, currentSong.index + 1 == songsList.count {
            return true
        }
        return false
    }

    public func isFirstSong() -> Bool
    {
        if let currentSong = self.currentSong, currentSong.index == 0 {
            return true
        }
        return false
    }

    // MARK: ColiseuPlayerDelegate

    public func remoteControlEvent(event: UIEvent)
    {
        if let delegate = self.delegate, event.type == UIEvent.EventType.remoteControl {
            switch event.subtype {
            case UIEvent.EventSubtype.remoteControlPlay:
                delegate.audioPlayer?(self, didReceiveRemoteControlPlayEvent: event.subtype)
            case UIEvent.EventSubtype.remoteControlPause:
                delegate.audioPlayer?(self, didReceiveRemoteControlPauseEvent: event.subtype)
            case UIEvent.EventSubtype.remoteControlPreviousTrack:
                delegate.audioPlayer?(self, didReceiveRemoteControlPreviousTrackEvent: event.subtype)
            case UIEvent.EventSubtype.remoteControlNextTrack:
                delegate.audioPlayer?(self, didReceiveRemoteControlNextTrackEvent: event.subtype)
            case UIEvent.EventSubtype.remoteControlBeginSeekingBackward:
                delegate.audioPlayer?(self, didReceiveRemoteControlBeginSeekingBackwardEvent: event.subtype)
            case UIEvent.EventSubtype.remoteControlEndSeekingBackward:
                delegate.audioPlayer?(self, didReceiveRemoteControlEndSeekingBackwardEvent: event.subtype)
            case UIEvent.EventSubtype.remoteControlBeginSeekingForward:
                delegate.audioPlayer?(self, didReceiveRemoteControlBeginSeekingForwardEvent: event.subtype)
            case UIEvent.EventSubtype.remoteControlEndSeekingForward:
                delegate.audioPlayer?(self, didReceiveRemoteControlEndSeekingForwardEvent: event.subtype)
            default: break
            }
        }
    }
}

// MARK: AudioPlayerProtocol

extension ColiseuPlayer: AudioPlayerProtocol
{
    public func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool)
    {
        if !flag {
            return
        }
        playNextSong(stopIfInvalid: true)
        if let repeatType = self.dataSource?.audioRepeatTypeInAudioPlayer?(self), self.audioPlayer?.isPlaying == false {
            switch repeatType {
            case ColiseuPlayerRepeat.None.rawValue:
                self.playerWillRepeat = false
            case ColiseuPlayerRepeat.One.rawValue:
                switch self.playerWillRepeat {
                case true?:
                    self.playerWillRepeat = false
                default:
                    self.playerWillRepeat = true
                    playSong(index: 0)
                }
            case ColiseuPlayerRepeat.All.rawValue:
                self.playerWillRepeat = true
                playSong(index: 0)
            default: break
            }
        }
    }
}

// MARK: shuffle Array

private extension Array
{
    mutating func shuffle() {
        if count < 2 { return }
        for i in 0..<(count - 1) {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            guard i != j else { continue }
            self.swapAt(i, j)
        }
    }
}
