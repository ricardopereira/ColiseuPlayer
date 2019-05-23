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
            Bundle(for: type(of: self)).path(forResource: "public_domain_1", ofType: "mp3")!,
            Bundle(for: type(of: self)).path(forResource: "public_domain_2", ofType: "mp3")!,
            Bundle(for: type(of: self)).path(forResource: "public_domain_3", ofType: "mp3")!
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
        XCTAssertEqual(actualResult, expectedResult, "testStartSession() should equal .playback")
    }

    func testStopSession() {
        // given
        let expectedResult = AVAudioSession.Category.ambient

        // when
        self.sut.startSession()
        self.sut.stopSession()
        let actualResult = AVAudioSession.sharedInstance().category

        // then
        XCTAssertEqual(actualResult, expectedResult, "testStopSession() should equal .ambient")
    }

    func testPlaySong() {
        // given
        let expectedResult = true

        // when
        self.sut.playSong(index: 0, songsList: self.list)
        let actualResult = self.sut.isPlaying

        // then
        XCTAssertEqual(actualResult, expectedResult, "testPlaySong() should be true")
    }

    func testPauseSong() {
        // given
        let expectedResult = false

        // when
        self.sut.playSong(index: 0, songsList: self.list)
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
}

extension ColiseuPlayerTests: ColiseuPlayerDataSource {
    func audioRepeatTypeInAudioPlayer(_ controller: ColiseuPlayer) -> ColiseuPlayerRepeat {
        return .none
    }
    
    func audioWillShuffleInAudioPlayer(_ controller: ColiseuPlayer) -> Bool {
        return false
    }
}
