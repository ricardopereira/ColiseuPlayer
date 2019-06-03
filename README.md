# ColiseuPlayer

[![Build Status](https://app.bitrise.io/app/9e385c486e60951f/status.svg?token=NIFH_3JCupMUSYhpOZWkHA&branch=master)](https://app.bitrise.io/app/9e385c486e60951f)
[![Swift 5](https://img.shields.io/badge/Swift-5-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Platforms iOS](https://img.shields.io/badge/Platforms-iOS-lightgray.svg?style=flat)](http://www.apple.com/ios/)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/ColiseuPlayer.svg?style=flat)](http://cocoapods.org/pods/ColiseuPlayer)
[![License MIT](https://img.shields.io/badge/License-MIT-lightgrey.svg?style=flat)](https://opensource.org/licenses/MIT)

ColiseuPlayer is an audio player framework written in Swift, created for [Coliseu](https://ricardopereira.eu) app.
It uses AVFoundation.

## Usage

```swift
import AVFoundation
import ColiseuPlayer

class ViewController: UIViewController, ColiseuPlayerDataSource, ColiseuPlayerDelegate {

    let player = ColiseuPlayer()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.player.startSession()
        self.player.dataSource = self

        var list = [AudioFile]()

        if let path = Bundle.main.path(forResource: "sampleAudio", ofType: "m4a") {
            let urlFile = URL(fileURLWithPath: path)
            let audio = AudioFile(url: urlFile)
            audio.artwork = UIImage(named: "image-cover-artwork")
            list.append(audio)
        }

        if list.count > 0 {
            // Play first song (it will continue playing with the current playlist)
            player.playSong(index: 0, songsList: list)
        }
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        self.player.stopSession()
    }

    override func remoteControlReceived(with event: UIEvent?) {
        self.player.didReceiveRemoteControl(event: event)
    }

    func audioRepeatType(in player: ColiseuPlayer) -> ColiseuPlayerRepeat {
        return .all
    }

    func audioWillShuffle(in player: ColiseuPlayer) -> Bool {
        return true
    }
}
```

## Requirements

- iOS 8.0+
- Xcode 10.2+

## Installation

#### <img src="https://cloud.githubusercontent.com/assets/432536/5252404/443d64f4-7952-11e4-9d26-fc5cc664cb61.png" width="24" height="24"> [Carthage]

[Carthage]: https://github.com/Carthage/Carthage

To install it, simply add the following line to your **Cartfile**:

```ruby
github "ricardopereira/ColiseuPlayer"
```

Then run `carthage update`.

Follow the current instructions in [Carthage's README][carthage-installation]
for up to date installation instructions.

[carthage-installation]: https://github.com/Carthage/Carthage#adding-frameworks-to-an-application

#### <img src="https://raw.githubusercontent.com/ricardopereira/resources/master/img/cocoapods.png" width="24" height="24"> [CocoaPods]

[CocoaPods]: http://cocoapods.org

To install it, simply add the following line to your Podfile:

```ruby
pod 'ColiseuPlayer'
```

You will also need to make sure you're opting into using frameworks:

```ruby
use_frameworks!
```

Then run `pod install` with CocoaPods 1.7.0 or newer.

#### Manually

ColiseuPlayer in your project requires the following steps:_

1. Add ColiseuPlayer as a [submodule](http://git-scm.com/docs/git-submodule) by opening the Terminal, `cd`-ing into your top-level project directory, and entering the command `git submodule add https://github.com/ricardopereira/coliseu.ios.player.git`
2. Open the `ColiseuPlayer` folder, and drag `ColiseuPlayer.xcodeproj` into the file navigator of your app project.
3. In Xcode, navigate to the target configuration window by clicking on the blue project icon, and selecting the application target under the "Targets" heading in the sidebar.
4. Ensure that the deployment target of ColiseuPlayer.framework matches that of the application target.
5. In the tab bar at the top of that window, open the "Build Phases" panel.
6. Expand the "Link Binary with Libraries" group, and add `ColiseuPlayer.framework`.
7. Click on the `+` button at the top left of the panel and select "New Copy Files Phase". Rename this new phase to "Copy Frameworks", set the "Destination" to "Frameworks", and add `ColiseuPlayer.framework`.

### Author

- [Ricardo Pereira](http://github.com/ricardopereira) ([@ricardopereiraw](https://twitter.com/ricardopereiraw))

### Main contributers

- [Zaid M. Said](http://github.com/SentulAsia) ([@SentulAsia](https://twitter.com/SentulAsia))

### License

ColiseuPlayer is released under the MIT license. See [LICENSE] for details.

[LICENSE]: /LICENSE
