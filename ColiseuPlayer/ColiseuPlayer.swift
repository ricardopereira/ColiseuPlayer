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
    optional func audioPlayer(controller: ColiseuPlayer, didReceiveRemoteControlPlayEvent eventSubtype: UIEventSubtype)

    /* audioPlayer:didReceiveRemoteControlPauseEvent: is called when pause button is clicked from remote control. */
    optional func audioPlayer(controller: ColiseuPlayer, didReceiveRemoteControlPauseEvent eventSubtype: UIEventSubtype)

    /* audioPlayer:didReceiveRemoteControlPreviousTrackEvent: is called when rewind button is clicked from remote control. */
    optional func audioPlayer(controller: ColiseuPlayer, didReceiveRemoteControlPreviousTrackEvent eventSubtype: UIEventSubtype)

    /* audioPlayer:didReceiveRemoteControlNextTrackEvent: is called when fast forward button is clicked from remote control. */
    optional func audioPlayer(controller: ColiseuPlayer, didReceiveRemoteControlNextTrackEvent eventSubtype: UIEventSubtype)

    /* audioPlayer:didReceiveRemoteControlBeginSeekingBackwardEvent: is called when begin seeking backward from remote control. */
    optional func audioPlayer(controller: ColiseuPlayer, didReceiveRemoteControlBeginSeekingBackwardEvent eventSubtype: UIEventSubtype)

    /* audioPlayer:didReceiveRemoteControlEndSeekingBackwardEvent: is called when seeking backward ended from remote control. */
    optional func audioPlayer(controller: ColiseuPlayer, didReceiveRemoteControlEndSeekingBackwardEvent eventSubtype: UIEventSubtype)

    /* audioPlayer:didReceiveRemoteControlBeginSeekingForwardEvent: is called when begin seeking forward from remote control. */
    optional func audioPlayer(controller: ColiseuPlayer, didReceiveRemoteControlBeginSeekingForwardEvent eventSubtype: UIEventSubtype)

    /* audioPlayer:didReceiveRemoteControlEndSeekingForwardEvent: is called when seeking forward ended from remote control. */
    optional func audioPlayer(controller: ColiseuPlayer, didReceiveRemoteControlEndSeekingForwardEvent eventSubtype: UIEventSubtype)
}

/* A protocol for datasource of ColiseuPlayer */
public protocol ColiseuPlayerDataSource: class
{
    // Determine whether audio is not going to repeat, repeat once or always repeat.
    func audioRepeatTypeInAudioPlayer(controller: ColiseuPlayer) -> ColiseuPlayerRepeat

    // Determine whether audio list is shuffled.
    func audioWillShuffleInAudioPlayer(controller: ColiseuPlayer) -> Bool
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
    internal var timer: NSTimer!

    // Playlist
    internal var currentSong: AudioFile?
    internal var songsList: [AudioFile]?

    // Events
    public var playerDidStart: function?
    public var playerDidStop: function?
    private var playerWillRepeat: Bool?

    // Delegate
    internal weak var delegate: ColiseuPlayerDelegate? {
        willSet {
            if let viewController = newValue as? UIViewController {
                UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
                viewController.becomeFirstResponder()
            }
            else {
                UIApplication.sharedApplication().endReceivingRemoteControlEvents()
            }
        }
        didSet {
            if let viewController = oldValue as? UIViewController {
                viewController.resignFirstResponder()
            }
        }
    }

    // DataSource
    internal weak var dataSource: ColiseuPlayerDataSource?

    public override init()
    {
        // Inherited
        super.init()

    }

    public func startSession()
    {
        // Session
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
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

    internal func remoteControlInfo(song: AudioFile)
    {
        var title: String = "Coliseu"
        if let bundleName = NSBundle.mainBundle().infoDictionary?["CFBundleName"] as? String {
            title = bundleName
        }
        // ? - Seeking test
        //let time = self.audioPlayer!.currentTime
        //self.audioPlayer!.currentTime = time + 30 //Seconds

        //slider.maximumValue = CMTimeGetSeconds([player duration])
        //slider.value = CMTimeGetSeconds(player.currentTime)
        //player.currentTime = CMTimeMakeWithSeconds((int)slider.value,1)

        // Remote Control info - ?
        if let artwork = song.artwork {
            let songInfo = [MPMediaItemPropertyTitle: song.title,
                MPMediaItemPropertyArtist: title,
                MPMediaItemPropertyArtwork: MPMediaItemArtwork(image: artwork),
                MPMediaItemPropertyPlaybackDuration: audioPlayer!.duration] as [String : AnyObject]

            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = songInfo
        }
        else {
            let songInfo = [MPMediaItemPropertyTitle: song.title,
                MPMediaItemPropertyArtist: title,
                //MPNowPlayingInfoPropertyElapsedPlaybackTime: time + 30,
                MPMediaItemPropertyPlaybackDuration: audioPlayer!.duration] as [String : AnyObject]

            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = songInfo
        }
    }

    private func prepareAudio(index: Int)
    {
        guard let songs = self.songsList where (index >= 0 && index < songs.count) else {
            return
        }
        prepareAudio(songs[index], index)
    }

    private func prepareAudio(song: AudioFile, _ index: Int)
    {
        // Keep alive audio at background
        if song.path == nil {
            self.currentSong = nil
            return
        }
        else {
            self.currentSong = song
            song.index = index
        }

        do {
            self.audioPlayer = try AVAudioPlayer(contentsOfURL: song.path!)
        }
        catch let error as NSError {
            print("A AVAudioPlayer contentsOfURL error occurred, here are the details:\n \(error)")
        }
        self.audioPlayer!.delegate = self
        self.audioPlayer!.prepareToPlay()

        remoteControlInfo(song)

        // ?
        song.duration = self.audioPlayer!.duration
    }

    private func songListIsValid() -> Bool
    {
        if self.songsList == nil || self.songsList!.count == 0 {
            return false
        }
        else {
            return true
        }
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
        if let dataSource = self.dataSource {
            if dataSource.audioWillShuffleInAudioPlayer(self) {
                self.songsList?.shuffle()
            }
        }
        // Prepare core audio
        prepareAudio(index)
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
        prepareAudio(index)
        // Play current song
        playSong()
    }

    public func pauseSong()
    {
        if self.audioPlayer!.playing {
            self.audioPlayer!.pause()
        }
    }

    public func stopSong()
    {
        if self.audioPlayer == nil || !self.audioPlayer!.playing {
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

    public func playNextSong(stopIfInvalid stopIfInvalid: Bool = false)
    {
        if let songs = self.songsList {
            if let song = self.currentSong {
                var index = song.index

                // Next song
                index++

                if index > songs.count - 1 {
                    if stopIfInvalid {
                        stopSong()
                    }
                    return
                }

                playSong(index)
            }
        }
    }

    public func playPreviousSong()
    {
        if let _ = self.songsList {
            if let song = self.currentSong {
                var index = song.index

                // Previous song
                index--

                if index < 0 {
                    return
                }

                playSong(index)
            }
        }
    }

    public func isLastSong() -> Bool
    {
        if let currentSong = self.currentSong, songsList = self.songsList {
            if currentSong.index + 1 == songsList.count {
                return true
            }
        }
        return false
    }

    public func isFirstSong() -> Bool
    {
        if let currentSong = self.currentSong {
            if currentSong.index == 0 {
                return true
            }
        }
        return false
    }

    // MARK: ColiseuPlayerDelegate

    public func remoteControlEvent(event: UIEvent)
    {
        if let delegate = self.delegate {
            if (event.type == UIEventType.RemoteControl) {
                switch event.subtype {
                case UIEventSubtype.RemoteControlPlay:
                    delegate.audioPlayer?(self, didReceiveRemoteControlPlayEvent: event.subtype)
                case UIEventSubtype.RemoteControlPause:
                    delegate.audioPlayer?(self, didReceiveRemoteControlPauseEvent: event.subtype)
                case UIEventSubtype.RemoteControlPreviousTrack:
                    delegate.audioPlayer?(self, didReceiveRemoteControlPreviousTrackEvent: event.subtype)
                case UIEventSubtype.RemoteControlNextTrack:
                    delegate.audioPlayer?(self, didReceiveRemoteControlNextTrackEvent: event.subtype)
                case UIEventSubtype.RemoteControlBeginSeekingBackward:
                    delegate.audioPlayer?(self, didReceiveRemoteControlBeginSeekingBackwardEvent: event.subtype)
                case UIEventSubtype.RemoteControlEndSeekingBackward:
                    delegate.audioPlayer?(self, didReceiveRemoteControlEndSeekingBackwardEvent: event.subtype)
                case UIEventSubtype.RemoteControlBeginSeekingForward:
                    delegate.audioPlayer?(self, didReceiveRemoteControlBeginSeekingForwardEvent: event.subtype)
                case UIEventSubtype.RemoteControlEndSeekingForward:
                    delegate.audioPlayer?(self, didReceiveRemoteControlEndSeekingForwardEvent: event.subtype)
                default: break
                }
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
        if self.audioPlayer?.playing == false {
            if let dataSource = self.dataSource {
                switch dataSource.audioRepeatTypeInAudioPlayer(self) {
                case ColiseuPlayerRepeat.None:
                    self.playerWillRepeat = false
                case ColiseuPlayerRepeat.One:
                    switch self.playerWillRepeat {
                    case true?:
                        self.playerWillRepeat = false
                    default:
                        self.playerWillRepeat = true
                        playSong(0)
                    }
                case ColiseuPlayerRepeat.All:
                    self.playerWillRepeat = true
                    playSong(0)
                }
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
            swap(&self[i], &self[j])
        }
    }
}
