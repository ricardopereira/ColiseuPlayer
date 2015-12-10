ColiseuPlayer is an audio player framework written in Swift, created for [Coliseu](http://ricardopereira.eu) app.
It uses AVFoundation.

[![Version](https://img.shields.io/cocoapods/v/ColiseuPlayer.svg?style=flat)](http://cocoapods.org/pods/ColiseuPlayer)

## Requirements

- iOS 8.0+ (not tested on Mac OS X)
- Xcode 7.1+

## Installation

#### <img src="https://dl.dropboxusercontent.com/u/11377305/resources/cocoapods.png" width="24" height="24"> [CocoaPods]

[CocoaPods]: http://cocoapods.org

To install it, simply add the following line to your Podfile:

```ruby
pod 'ColiseuPlayer'
```

You will also need to make sure you're opting into using frameworks:

```ruby
use_frameworks!
```

Then run `pod install` with CocoaPods 0.36 or newer.

#### Manually

ColiseuPlayer in your project requires the following steps:_

1. Add ColiseuPlayer as a [submodule](http://git-scm.com/docs/git-submodule) by opening the Terminal, `cd`-ing into your top-level project directory, and entering the command `git submodule add https://github.com/ricardopereira/coliseu.ios.player.git`
2. Open the `ColiseuPlayer` folder, and drag `ColiseuPlayer.xcodeproj` into the file navigator of your app project.
3. In Xcode, navigate to the target configuration window by clicking on the blue project icon, and selecting the application target under the "Targets" heading in the sidebar.
4. Ensure that the deployment target of ColiseuPlayer.framework matches that of the application target.
5. In the tab bar at the top of that window, open the "Build Phases" panel.
6. Expand the "Link Binary with Libraries" group, and add `ColiseuPlayer.framework`.
7. Click on the `+` button at the top left of the panel and select "New Copy Files Phase". Rename this new phase to "Copy Frameworks", set the "Destination" to "Frameworks", and add `ColiseuPlayer.framework`.

---

## Usage

```swift
import ColiseuPlayer

class ViewController: UIViewController, ColiseuPlayerDataSource, ColiseuPlayerDelegate {

    let player = ColiseuPlayer()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.player.startSession()
        self.player.dataSource = self
        self.player.delegate = self

        var list = [AudioFile]()

        if let urlFile = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource("1.m4a", ofType: nil)!) {
            list.append(AudioFile(url: urlFile))
        }

        if let urlFile = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource("2.m4a", ofType: nil)!) {
            let audio = AudioFile(url: urlFile)
            audio.artwork = UIImage(named: "image-cover-for-2")
            list.append(audio)
        }

        if list.count > 0 {
            // Play first song (it will continue playing with the current playlist)
            player.playSong(0, songsList: list)
        }
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        self.player.stopSession()
        // required for endReceivingRemoteControlEvents and resignFirstResponder
        self.player.delegate = nil
    }

    func audioRepeatTypeInAudioPlayer(controller: ColiseuPlayer) -> ColiseuPlayerRepeat.RawValue {
        return ColiseuPlayerRepeat.All.rawValue
    }

    func audioWillShuffleInAudioPlayer(controller: ColiseuPlayer) -> Bool {
        return true
    }

    func audioPlayer(controller: ColiseuPlayer, didReceiveRemoteControlPlayEvent eventSubtype: UIEventSubtype) {
        self.player.playSong()
    }

    func func audioPlayer(controller: ColiseuPlayer, didReceiveRemoteControlPauseEvent eventSubtype: UIEventSubtype) {
        self.player.pauseSong()
    }

    func audioPlayer(controller: ColiseuPlayer, didReceiveRemoteControlPreviousTrackEvent eventSubtype: UIEventSubtype) {
        self.player.playPreviousSong()
    }

    func audioPlayer(controller: ColiseuPlayer, didReceiveRemoteControlNextTrackEvent eventSubtype: UIEventSubtype) {
        self.player.playNextSong(stopIfInvalid: true)
    }
}
````

### Contact

Follow Coliseu on Twitter ([@coliseuapp](https://twitter.com/coliseuapp))

### Author

- [Ricardo Pereira](http://github.com/ricardopereira) ([@ricardopereiraw](https://twitter.com/ricardopereiraw))

### Main contributers

- [Zaid M. Said](http://github.com/SentulAsia) ([@SentulAsia](https://twitter.com/SentulAsia))

### License

ColiseuPlayer is released under the MIT license. See [LICENSE] for details.

[LICENSE]: /LICENSE
