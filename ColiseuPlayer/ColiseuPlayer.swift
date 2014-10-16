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
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool)
}

public class ColiseuPlayer: NSObject
{
    public typealias function = () -> ()

    var audioPlayer: AVAudioPlayer?
    var timer: NSTimer!

    // Playlist
    private var currentSong: AudioFile?
    var songsList: [AudioFile]?

    // Events
    public var playerDidStart: function?
    public var playerDidStop: function?

    public override init()
    {
        // Inherited
        super.init()

    }

    public func startSession()
    {
        // Session
        AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, error: nil)
        AVAudioSession.sharedInstance().setActive(true, error: nil)
    }

    private func prepareAudio(index: Int)
    {
        if let songs = songsList {
            if index >= 0 && index < songs.count {
                prepareAudio(songs[index], index)
            }
        }
    }

    private func prepareAudio(song: AudioFile, _ index: Int)
    {
        // Keep alive audio at background
        if song.path == nil {
            currentSong = nil
            return
        }
        else {
            currentSong = song
            song.index = index
        }

        audioPlayer = AVAudioPlayer(contentsOfURL: song.path, error: nil)
        audioPlayer!.delegate = self
        audioPlayer!.prepareToPlay()

        // ? - Seeking test
        //let time = audioPlayer!.currentTime
        //audioPlayer!.currentTime = time + 30 //Seconds

        //slider.maximumValue = CMTimeGetSeconds([player duration]);
        //slider.value = CMTimeGetSeconds(player.currentTime);
        //player.currentTime = CMTimeMakeWithSeconds((int)slider.value,1);

        // Remote Control info - ?
        let songInfo = [MPMediaItemPropertyTitle: "Coliseu",
            MPMediaItemPropertyArtist: song.title,
            //MPNowPlayingInfoPropertyElapsedPlaybackTime:  time + 30,
            MPMediaItemPropertyPlaybackDuration: audioPlayer!.duration]

        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = songInfo
        // ?
        song.duration = audioPlayer!.duration
    }

    private func songListIsValid() -> Bool
    {
        if songsList == nil || songsList!.count == 0 {
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
        if let event = playerDidStart {
            event()
        }
        audioPlayer!.play()
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
        if audioPlayer!.playing {
            audioPlayer!.pause()
        }
    }

    public func stopSong()
    {
        if audioPlayer == nil || !audioPlayer!.playing {
            return
        }

        audioPlayer!.stop();
        if let event = playerDidStop {
            event()
        }
        if let current = currentSong {
            prepareAudio(current, current.index)
        }
    }

    public func playNextSong(stopIfInvalid: Bool = false)
    {
        if let songs = songsList {
            if let song = currentSong {
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
        if let songs = songsList {
            if let song = currentSong {
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

    // isLastSong

    // isFirstSong
}

// MARK: AudioPlayerProtocol

extension ColiseuPlayer: AudioPlayerProtocol
{
    public func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool)
    {
        if !flag {
            return
        }
        playNextSong(stopIfInvalid: true)
    }
}