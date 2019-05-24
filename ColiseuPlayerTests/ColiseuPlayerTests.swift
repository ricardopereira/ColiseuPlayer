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
    var audioPlayerDidReceiveRemoteControlPlayEventCalled = false
    var audioPlayerDidReceiveRemoteControlPauseEventCalled = false
    var audioPlayerDidReceiveRemoteControlPreviousTrackEventCalled = false
    var audioPlayerDidReceiveRemoteControlNextTrackEventCalled = false

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.sut = ColiseuPlayer()
        self.sut.dataSource = self
        self.sut.delegate = self
        self.list = []
        let paths = [
            Bundle(for: type(of: self)).path(forResource: "public_domain_1", ofType: "mp3")!,
            Bundle(for: type(of: self)).path(forResource: "public_domain_2", ofType: "mp3")!,
            Bundle(for: type(of: self)).path(forResource: "public_domain_3", ofType: "mp3")!
        ]
        for path in paths {
            let urlFile = URL(fileURLWithPath: path)
            let audio = AudioFile(url: urlFile)
            self.list.append(audio)
        }
        self.audioPlayerDidReceiveRemoteControlPlayEventCalled = false
        self.audioPlayerDidReceiveRemoteControlPauseEventCalled = false
        self.audioPlayerDidReceiveRemoteControlPreviousTrackEventCalled = false
        self.audioPlayerDidReceiveRemoteControlNextTrackEventCalled = false
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        self.sut.stopSong()
        self.sut.stopSession()
        self.list = nil
        self.sut = nil
    }

    func testStartSession() {
        // given
        let expectedResult = AVAudioSession.Category.playback

        // when
        self.sut.startSession()
        let actualResult = AVAudioSession.sharedInstance().category

        // then
        XCTAssertEqual(actualResult, expectedResult, "testStartSession() should equal .playback")
    }

    func testStopSession() {
        // given
        let expectedResult = AVAudioSession.Category.ambient
        self.sut.startSession()

        // when
        self.sut.stopSession()
        let actualResult = AVAudioSession.sharedInstance().category

        // then
        XCTAssertEqual(actualResult, expectedResult, "testStopSession() should equal .ambient")
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
        XCTAssertEqual(actualResult, expectedResult, "testPlaySong() should be true")
    }

    func testPlaySongIndexSongsList() {
        // given
        let expectedResult = true

        // when
        self.sut.playSong(index: 0, songsList: self.list)
        let actualResult = self.sut.isPlaying

        // then
        XCTAssertEqual(actualResult, expectedResult, "testPlaySong(index:songsList:) should be true")
    }

    func testPlaySongIndex() {
        // given
        let expectedResult = true
        self.sut.playSong(index: 0, songsList: self.list)
        self.sut.stopSong()

        // when
        self.sut.playSong(index: 1)
        let actualResult = self.sut.isPlaying

        // then
        XCTAssertEqual(actualResult, expectedResult, "testPlaySongIndex() should be true")
    }

    func testPauseSong() {
        // given
        let expectedResult = false
        self.sut.playSong(index: 0, songsList: self.list)

        // when
        self.sut.pauseSong()
        let actualResult = self.sut.isPlaying

        // then
        XCTAssertEqual(actualResult, expectedResult, "testPauseSong() should be false")
    }

    func testStopSong() {
        // given
        let expectedResult = false

        // when
        self.sut.playSong(index: 0, songsList: self.list)
        self.sut.stopSong()
        let actualResult = self.sut.isPlaying

        // then
        XCTAssertEqual(actualResult, expectedResult, "testStopSong() should be false")
    }

    func testPlayNextSong() {
        // given
        let expectedResult = true
        self.sut.playSong(index: 1, songsList: self.list)
        self.sut.stopSong()

        // when
        self.sut.playNextSong()
        let actualResult = self.sut.isPlaying

        // then
        XCTAssertEqual(actualResult, expectedResult, "testPlayNextSong() should be true")
    }

    func testPlayNextSongGivenLastSong() {
        // given
        let expectedResult = false
        self.sut.playSong(index: 2, songsList: self.list)
        self.sut.stopSong()

        // when
        self.sut.playNextSong()
        let actualResult = self.sut.isPlaying

        // then
        XCTAssertEqual(actualResult, expectedResult, "testPlayNextSongGivenLastSong() should be false")
    }

    func testPlayPreviousSong() {
        // given
        let expectedResult = true
        self.sut.playSong(index: 1, songsList: self.list)
        self.sut.stopSong()

        // when
        self.sut.playPreviousSong()
        let actualResult = self.sut.isPlaying

        // then
        XCTAssertEqual(actualResult, expectedResult, "testPlayPreviousSong() should be true")
    }

    func testPlayPreviousSongGivenFirstSong() {
        // given
        let expectedResult = false
        self.sut.playSong(index: 0, songsList: self.list)
        self.sut.stopSong()

        // when
        self.sut.playPreviousSong()
        let actualResult = self.sut.isPlaying

        // then
        XCTAssertEqual(actualResult, expectedResult, "testPlayPreviousSongGivenFirstSong() should be false")
    }

    func testDidReceiveRemoteControlPlayEvent() {
        // given
        let expectedResult = true
        self.sut.playSong(index: 1, songsList: self.list)
        self.sut.stopSong()
        let event = UIEventPlayDouble()

        // when
        self.sut.didReceiveRemoteControl(event: event)
        let actualResult = self.audioPlayerDidReceiveRemoteControlPlayEventCalled

        // then
        XCTAssertEqual(actualResult, expectedResult, "didReceiveRemoteControl(event:) is remote control play should be true")
    }

    func testDidReceiveRemoteControlPauseEvent() {
        // given
        let expectedResult = true
        self.sut.playSong(index: 1, songsList: self.list)
        self.sut.stopSong()
        let event = UIEventPauseDouble()

        // when
        self.sut.didReceiveRemoteControl(event: event)
        let actualResult = self.audioPlayerDidReceiveRemoteControlPauseEventCalled

        // then
        XCTAssertEqual(actualResult, expectedResult, "didReceiveRemoteControl(event:) is remote control pause should be true")
    }

    func testDidReceiveRemoteControlPreviousTrackEvent() {
        // given
        let expectedResult = true
        self.sut.playSong(index: 1, songsList: self.list)
        self.sut.stopSong()
        let event = UIEventPreviousTrackDouble()

        // when
        self.sut.didReceiveRemoteControl(event: event)
        let actualResult = self.audioPlayerDidReceiveRemoteControlPreviousTrackEventCalled

        // then
        XCTAssertEqual(actualResult, expectedResult, "didReceiveRemoteControl(event:) is remote control previous track should be true")
    }

    func testDidReceiveRemoteControlNextTrackEvent() {
        // given
        let expectedResult = true
        self.sut.playSong(index: 1, songsList: self.list)
        self.sut.stopSong()
        let event = UIEventNextTrackDouble()

        // when
        self.sut.didReceiveRemoteControl(event: event)
        let actualResult = self.audioPlayerDidReceiveRemoteControlNextTrackEventCalled

        // then
        XCTAssertEqual(actualResult, expectedResult, "didReceiveRemoteControl(event:) is remote control next track should be true")
    }
}

extension ColiseuPlayerTests {
    class UIEventRemoteControlDouble: UIEvent {
        override var type: UIEvent.EventType {
            get {
                return UIEvent.EventType.remoteControl
            }
        }
    }

    class UIEventPlayDouble: UIEventRemoteControlDouble {
        override var subtype: UIEvent.EventSubtype {
            get {
                return UIEvent.EventSubtype.remoteControlPlay
            }
        }
    }

    class UIEventPauseDouble: UIEventRemoteControlDouble {
        override var subtype: UIEvent.EventSubtype {
            get {
                return UIEvent.EventSubtype.remoteControlPause
            }
        }
    }

    class UIEventPreviousTrackDouble: UIEventRemoteControlDouble {
        override var subtype: UIEvent.EventSubtype {
            get {
                return UIEvent.EventSubtype.remoteControlPreviousTrack
            }
        }
    }

    class UIEventNextTrackDouble: UIEventRemoteControlDouble {
        override var subtype: UIEvent.EventSubtype {
            get {
                return UIEvent.EventSubtype.remoteControlNextTrack
            }
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

extension ColiseuPlayerTests: ColiseuPlayerDelegate {
    func audioPlayerDidReceiveRemoteControlPlayEvent(_ player: ColiseuPlayer, withSubtype eventSubtype: UIEvent.EventSubtype) {
        self.audioPlayerDidReceiveRemoteControlPlayEventCalled = true
    }

    func audioPlayerDidReceiveRemoteControlPauseEvent(_ player: ColiseuPlayer, withSubtype eventSubtype: UIEvent.EventSubtype) {
        self.audioPlayerDidReceiveRemoteControlPauseEventCalled = true
    }

    func audioPlayerDidReceiveRemoteControlPreviousTrackEvent(_ player: ColiseuPlayer, withSubtype eventSubtype: UIEvent.EventSubtype) {
        self.audioPlayerDidReceiveRemoteControlPreviousTrackEventCalled = true
    }

    func audioPlayerDidReceiveRemoteControlNextTrackEvent(_ player: ColiseuPlayer, withSubtype eventSubtype: UIEvent.EventSubtype) {
        self.audioPlayerDidReceiveRemoteControlNextTrackEventCalled = true
    }
}
