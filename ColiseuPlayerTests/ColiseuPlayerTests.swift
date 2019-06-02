//
//  ColiseuPlayerTests.swift
//  ColiseuPlayerTests
//
//  Created by Ricardo Pereira on 09/10/2014.
//  Copyright (c) 2014 Ricardo Pereira. All rights reserved.
//

import AVFoundation
import XCTest
@testable import ColiseuPlayer

class ColiseuPlayerTests: XCTestCase {

    var sut: ColiseuPlayer!
    var list: [AudioFile]!
    var delegatorSpy: DelegatorSpy!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.sut = ColiseuPlayer()
        self.sut.engine = ColiseuPlayerEngineMock()
        self.delegatorSpy = DelegatorSpy()
        self.sut.dataSource = self
        self.sut.delegate = self.delegatorSpy
        self.list = []
        let paths = [
            Bundle(for: type(of: self)).path(forResource: "public_domain_sound_1", ofType: "mp3")!,
            Bundle(for: type(of: self)).path(forResource: "public_domain_sound_2", ofType: "mp3")!,
            Bundle(for: type(of: self)).path(forResource: "public_domain_sound_3", ofType: "mp3")!
        ]
        for path in paths {
            let urlFile = URL(fileURLWithPath: path)
            let audio = AudioFile(url: urlFile)
            self.list.append(audio)
        }
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        self.sut.stopSong()
        self.sut.stopSession()
        self.list = nil
        self.delegatorSpy = nil
        self.sut = nil
    }

    func testStartSession() {
        // given
        let expectedResult = AVAudioSession.Category.playback

        // when
        self.sut.startSession()
        let actualResult = AVAudioSession.sharedInstance().category

        // then
        XCTAssertEqual(actualResult, expectedResult, "startSession() should result category equal .playback")
    }

    func testStopSession() {
        // given
        let expectedResult = AVAudioSession.Category.ambient
        self.sut.startSession()

        // when
        self.sut.stopSession()
        let actualResult = AVAudioSession.sharedInstance().category

        // then
        XCTAssertEqual(actualResult, expectedResult, "stopSession() should result category equal .ambient")
    }

    func testPlaySong() {
        // given
        let expectedResult = true
        self.sut.playSong(index: 0, songsList: self.list)
        self.sut.stopSong()

        // when
        self.sut.playSong()
        let actualResult = self.sut.isPlaying

        // then
        XCTAssertEqual(actualResult, expectedResult, "playSong() should play song")
    }

    func testPlaySongIndexSongsList() {
        // given
        let expectedResult = true

        // when
        self.sut.playSong(index: 0, songsList: self.list)
        let actualResult = self.sut.isPlaying

        // then
        XCTAssertEqual(actualResult, expectedResult, "playSong(index:songsList:) should play song")
    }

    func testPlaySongIndexIsValidIndex() {
        // given
        let expectedResult = true
        self.sut.playSong(index: 0, songsList: self.list)
        self.sut.stopSong()

        // when
        self.sut.playSong(index: 1)
        let actualResult = self.sut.isPlaying

        // then
        XCTAssertEqual(actualResult, expectedResult, "playSong(index:) is valid index should play song")
    }

    func testPlaySongIndexIsInvalidIndex() {
        // given
        let expectedResult = false
        self.sut.playSong(index: 0, songsList: self.list)
        self.sut.stopSong()

        // when
        self.sut.playSong(index: 3)
        let actualResult = self.sut.isPlaying

        // then
        XCTAssertEqual(actualResult, expectedResult, "playSong(index:) is invalid index should not play song")
    }

    func testPauseSong() {
        // given
        let expectedResult = false
        self.sut.playSong(index: 0, songsList: self.list)

        // when
        self.sut.pauseSong()
        let actualResult = self.sut.isPlaying

        // then
        XCTAssertEqual(actualResult, expectedResult, "pauseSong() should not play song")
    }

    func testStopSong() {
        // given
        let expectedResult = false
        self.sut.playSong(index: 0, songsList: self.list)

        // when
        self.sut.stopSong()
        let actualResult = self.sut.isPlaying

        // then
        XCTAssertEqual(actualResult, expectedResult, "stopSong() should not play song")
    }

    func testPlayNextSongIsNotLastSong() {
        // given
        let expectedResult = true
        self.sut.playSong(index: 1, songsList: self.list)
        self.sut.stopSong()

        // when
        self.sut.playNextSong()
        let actualResult = self.sut.isPlaying

        // then
        XCTAssertEqual(actualResult, expectedResult, "playNextSong() is not last song should play song")
    }

    func testPlayNextSongIsLastSong() {
        // given
        let expectedResult = false
        self.sut.playSong(index: 2, songsList: self.list)
        self.sut.stopSong()

        // when
        self.sut.playNextSong()
        let actualResult = self.sut.isPlaying

        // then
        XCTAssertEqual(actualResult, expectedResult, "playNextSong() is last song should not play song")
    }

    func testPlayPreviousSongIsNotFirstSong() {
        // given
        let expectedResult = true
        self.sut.playSong(index: 1, songsList: self.list)
        self.sut.stopSong()

        // when
        self.sut.playPreviousSong()
        let actualResult = self.sut.isPlaying

        // then
        XCTAssertEqual(actualResult, expectedResult, "playPreviousSong() is not first song should play song")
    }

    func testPlayPreviousSongIsFirstSong() {
        // given
        let expectedResult = false
        self.sut.playSong(index: 0, songsList: self.list)
        self.sut.stopSong()

        // when
        self.sut.playPreviousSong()
        let actualResult = self.sut.isPlaying

        // then
        XCTAssertEqual(actualResult, expectedResult, "playPreviousSong() is first song should not play song")
    }

    func testDidReceiveRemoteControlPlayEvent() {
        // given
        let expectedResult = true
        let event = UIEventPlayStub()

        // when
        self.sut.didReceiveRemoteControl(event: event)
        let actualResult = self.delegatorSpy.audioPlayerDidReceiveRemoteControlPlayEventCalled

        // then
        XCTAssertEqual(actualResult, expectedResult, "didReceiveRemoteControl(event:) is remote control play should be true")
    }

    func testDidReceiveRemoteControlPauseEvent() {
        // given
        let expectedResult = true
        let event = UIEventPauseStub()

        // when
        self.sut.didReceiveRemoteControl(event: event)
        let actualResult = self.delegatorSpy.audioPlayerDidReceiveRemoteControlPauseEventCalled

        // then
        XCTAssertEqual(actualResult, expectedResult, "didReceiveRemoteControl(event:) is remote control pause should be true")
    }

    func testDidReceiveRemoteControlPreviousTrackEvent() {
        // given
        let expectedResult = true
        let event = UIEventPreviousTrackStub()

        // when
        self.sut.didReceiveRemoteControl(event: event)
        let actualResult = self.delegatorSpy.audioPlayerDidReceiveRemoteControlPreviousTrackEventCalled

        // then
        XCTAssertEqual(actualResult, expectedResult, "didReceiveRemoteControl(event:) is remote control previous track should be true")
    }

    func testDidReceiveRemoteControlNextTrackEvent() {
        // given
        let expectedResult = true
        let event = UIEventNextTrackStub()

        // when
        self.sut.didReceiveRemoteControl(event: event)
        let actualResult = self.delegatorSpy.audioPlayerDidReceiveRemoteControlNextTrackEventCalled

        // then
        XCTAssertEqual(actualResult, expectedResult, "didReceiveRemoteControl(event:) is remote control next track should be true")
    }

    func testDidReceiveRemoteControlBeginSeekingBackwardEvent() {
        // given
        let expectedResult = true
        let event = UIEventBeginSeekingBackwardStub()

        // when
        self.sut.didReceiveRemoteControl(event: event)
        let actualResult = self.delegatorSpy.audioPlayerDidReceiveRemoteControlBeginSeekingBackwardEventCalled

        // then
        XCTAssertEqual(actualResult, expectedResult, "didReceiveRemoteControl(event:) is remote control begin seeking backward should be true")
    }

    func testDidReceiveRemoteControlEndSeekingBackwardEvent() {
        // given
        let expectedResult = true
        let event = UIEventEndSeekingBackwardStub()

        // when
        self.sut.didReceiveRemoteControl(event: event)
        let actualResult = self.delegatorSpy.audioPlayerDidReceiveRemoteControlEndSeekingBackwardEventCalled

        // then
        XCTAssertEqual(actualResult, expectedResult, "didReceiveRemoteControl(event:) is remote control end seeking backward should be true")
    }

    func testDidReceiveRemoteControlBeginSeekingForwardEvent() {
        // given
        let expectedResult = true
        let event = UIEventBeginSeekingForwardStub()

        // when
        self.sut.didReceiveRemoteControl(event: event)
        let actualResult = self.delegatorSpy.audioPlayerDidReceiveRemoteControlBeginSeekingForwardEventCalled

        // then
        XCTAssertEqual(actualResult, expectedResult, "didReceiveRemoteControl(event:) is remote control begin seeking forward should be true")
    }

    func testDidReceiveRemoteControlEndSeekingForwardEvent() {
        // given
        let expectedResult = true
        let event = UIEventEndSeekingForwardStub()

        // when
        self.sut.didReceiveRemoteControl(event: event)
        let actualResult = self.delegatorSpy.audioPlayerDidReceiveRemoteControlEndSeekingForwardEventCalled

        // then
        XCTAssertEqual(actualResult, expectedResult, "didReceiveRemoteControl(event:) is remote control end seeking forward should be true")
    }
}

extension ColiseuPlayerTests {
    class ColiseuPlayerEngineMock: ColiseuPlayerEngine {
        override func initAudioPlayer(url: URL) -> AVAudioPlayer? {
            do {
                return try AVAudioPlayerMock(contentsOf: url)
            }
            catch let error {
                print("AVAudioPlayer error occurred:\n \(error)")
            }
            return nil
        }
    }

    class AVAudioPlayerMock: AVAudioPlayer {
        private var isPlayingMock: Bool = false

        override var isPlaying: Bool {
            return self.isPlayingMock
        }

        override func play() -> Bool {
            self.isPlayingMock = true
            super.play()
            return self.isPlayingMock
        }

        override func pause() {
            self.isPlayingMock = false
            super.pause()
        }

        override func stop() {
            self.isPlayingMock = false
            super.stop()
        }
    }
}

extension ColiseuPlayerTests {
    class UIEventRemoteControlStub: UIEvent {
        override var type: UIEvent.EventType {
            return UIEvent.EventType.remoteControl
        }
    }

    class UIEventPlayStub: UIEventRemoteControlStub {
        override var subtype: UIEvent.EventSubtype {
            return UIEvent.EventSubtype.remoteControlPlay
        }
    }

    class UIEventPauseStub: UIEventRemoteControlStub {
        override var subtype: UIEvent.EventSubtype {
            return UIEvent.EventSubtype.remoteControlPause
        }
    }

    class UIEventPreviousTrackStub: UIEventRemoteControlStub {
        override var subtype: UIEvent.EventSubtype {
            return UIEvent.EventSubtype.remoteControlPreviousTrack
        }
    }

    class UIEventNextTrackStub: UIEventRemoteControlStub {
        override var subtype: UIEvent.EventSubtype {
            return UIEvent.EventSubtype.remoteControlNextTrack
        }
    }

    class UIEventBeginSeekingBackwardStub: UIEventRemoteControlStub {
        override var subtype: UIEvent.EventSubtype {
            return UIEvent.EventSubtype.remoteControlBeginSeekingBackward
        }
    }

    class UIEventEndSeekingBackwardStub: UIEventRemoteControlStub {
        override var subtype: UIEvent.EventSubtype {
            return UIEvent.EventSubtype.remoteControlEndSeekingBackward
        }
    }

    class UIEventBeginSeekingForwardStub: UIEventRemoteControlStub {
        override var subtype: UIEvent.EventSubtype {
            return UIEvent.EventSubtype.remoteControlBeginSeekingForward
        }
    }

    class UIEventEndSeekingForwardStub: UIEventRemoteControlStub {
        override var subtype: UIEvent.EventSubtype {
            return UIEvent.EventSubtype.remoteControlEndSeekingForward
        }
    }
}

extension ColiseuPlayerTests: ColiseuPlayerDataSource {
    func audioRepeatType(in player: ColiseuPlayer) -> ColiseuPlayerRepeat {
        return .none
    }

    func audioWillShuffle(in player: ColiseuPlayer) -> Bool {
        return false
    }
}

extension ColiseuPlayerTests {
    class DelegatorSpy: ColiseuPlayerDelegate {
        var audioPlayerDidReceiveRemoteControlPlayEventCalled = false
        func audioPlayerDidReceiveRemoteControlPlayEvent(_ player: ColiseuPlayer) {
            self.audioPlayerDidReceiveRemoteControlPlayEventCalled = true
        }

        var audioPlayerDidReceiveRemoteControlPauseEventCalled = false
        func audioPlayerDidReceiveRemoteControlPauseEvent(_ player: ColiseuPlayer) {
            self.audioPlayerDidReceiveRemoteControlPauseEventCalled = true
        }

        var audioPlayerDidReceiveRemoteControlPreviousTrackEventCalled = false
        func audioPlayerDidReceiveRemoteControlPreviousTrackEvent(_ player: ColiseuPlayer) {
            self.audioPlayerDidReceiveRemoteControlPreviousTrackEventCalled = true
        }

        var audioPlayerDidReceiveRemoteControlNextTrackEventCalled = false
        func audioPlayerDidReceiveRemoteControlNextTrackEvent(_ player: ColiseuPlayer) {
            self.audioPlayerDidReceiveRemoteControlNextTrackEventCalled = true
        }

        var audioPlayerDidReceiveRemoteControlBeginSeekingBackwardEventCalled = false
        func audioPlayerDidReceiveRemoteControlBeginSeekingBackwardEvent(_ player: ColiseuPlayer) {
            self.audioPlayerDidReceiveRemoteControlBeginSeekingBackwardEventCalled = true
        }

        var audioPlayerDidReceiveRemoteControlEndSeekingBackwardEventCalled = false
        func audioPlayerDidReceiveRemoteControlEndSeekingBackwardEvent(_ player: ColiseuPlayer) {
            self.audioPlayerDidReceiveRemoteControlEndSeekingBackwardEventCalled = true
        }

        var audioPlayerDidReceiveRemoteControlBeginSeekingForwardEventCalled = false
        func audioPlayerDidReceiveRemoteControlBeginSeekingForwardEvent(_ player: ColiseuPlayer) {
            self.audioPlayerDidReceiveRemoteControlBeginSeekingForwardEventCalled = true
        }

        var audioPlayerDidReceiveRemoteControlEndSeekingForwardEventCalled = false
        func audioPlayerDidReceiveRemoteControlEndSeekingForwardEvent(_ player: ColiseuPlayer) {
            self.audioPlayerDidReceiveRemoteControlEndSeekingForwardEventCalled = true
        }
    }
}
