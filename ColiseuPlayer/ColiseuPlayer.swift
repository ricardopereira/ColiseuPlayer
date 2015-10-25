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
@objc public protocol ColiseuPlayerDelegate: class {
    /* audioPlayer:didReceiveRemoteControlBeginSeekingBackwardEvent: is called when begin seeking backward from remote control. */
    optional func audioPlayer(controller: ColiseuPlayer, didReceiveRemoteControlBeginSeekingBackwardEvent eventSubtype: UIEventSubtype)

    /* audioPlayer:didReceiveRemoteControlEndSeekingBackwardEvent: is called when seeking backward ended from remote control. */
    optional func audioPlayer(controller: ColiseuPlayer, didReceiveRemoteControlEndSeekingBackwardEvent eventSubtype: UIEventSubtype)

    /* audioPlayer:didReceiveRemoteControlBeginSeekingForwardEvent: is called when begin seeking forward from remote control. */
    optional func audioPlayer(controller: ColiseuPlayer, didReceiveRemoteControlBeginSeekingForwardEvent eventSubtype: UIEventSubtype)

    /* audioPlayer:didReceiveRemoteControlEndSeekingForwardEvent: is called when seeking forward ended from remote control. */
    optional func audioPlayer(controller: ColiseuPlayer, didReceiveRemoteControlEndSeekingForwardEvent eventSubtype: UIEventSubtype)
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

    // Delegate
    internal weak var delegate: ColiseuPlayerDelegate?
    {
        willSet {
            if let viewController = newValue as? UIView {
                UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
                viewController.becomeFirstResponder()
            }
            else {
                UIApplication.sharedApplication().endReceivingRemoteControlEvents()
            }
        }
    }

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
        // ? - Seeking test
        //let time = self.audioPlayer!.currentTime
        //self.audioPlayer!.currentTime = time + 30 //Seconds

        //slider.maximumValue = CMTimeGetSeconds([player duration])
        //slider.value = CMTimeGetSeconds(player.currentTime)
        //player.currentTime = CMTimeMakeWithSeconds((int)slider.value,1)

        // Remote Control info - ?
        let songInfo = [MPMediaItemPropertyTitle: "Coliseu",
            MPMediaItemPropertyArtist: song.title,
            //MPNowPlayingInfoPropertyElapsedPlaybackTime: time + 30,
            MPMediaItemPropertyPlaybackDuration: audioPlayer!.duration] as [String : AnyObject]

        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = songInfo
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
        if self.songsList != nil && self.currentSong != nil {
            if self.currentSong!.index + 1 == self.songsList!.count {
                return true
            }
        }
        return false
    }

    public func isFirstSong() -> Bool
    {
        if self.currentSong != nil {
            if self.currentSong!.index == 0 {
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
    }
}
