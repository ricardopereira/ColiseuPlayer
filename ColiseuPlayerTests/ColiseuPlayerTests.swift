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

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.sut = ColiseuPlayer()
        self.sut.dataSource = self
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
        let expectedResult = true
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
}

extension ColiseuPlayerTests: ColiseuPlayerDataSource {
    func audioRepeatType(in player: ColiseuPlayer) -> ColiseuPlayerRepeat {
        return .none
    }

    func audioWillShuffle(in player: ColiseuPlayer) -> Bool {
        return false
    }
}
