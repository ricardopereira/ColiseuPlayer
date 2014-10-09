ColiseuPlayer (Beta) is an audio player framework written in Swift, created for [Coliseu](http://ricardopereira.eu) app.
It uses AVFoundation.

## Requirements

- iOS 8.0+ (not tested on Mac OS X)
- Xcode 6.0+

## Installation

_Due to the current lack of [proper infrastructure](http://cocoapods.org) for Swift dependency management, using ColiseuPlayer in your project requires the following steps:_

1. Add ColiseuPlayer as a [submodule](http://git-scm.com/docs/git-submodule) by opening the Terminal, `cd`-ing into your top-level project directory, and entering the command `git submodule add https://github.com/ricardopereira/coliseu.ios.player.git`
2. Open the `ColiseuPlayer` folder, and drag `ColiseuPlayer.xcodeproj` into the file navigator of your app project.
3. In Xcode, navigate to the target configuration window by clicking on the blue project icon, and selecting the application target under the "Targets" heading in the sidebar.
4. Ensure that the deployment target of ColiseuPlayer.framework matches that of the application target.
5. In the tab bar at the top of that window, open the "Build Phases" panel.
6. Expand the "Link Binary with Libraries" group, and add `ColiseuPlayer.framework`.
7. Click on the `+` button at the top left of the panel and select "New Copy Files Phase". Rename this new phase to "Copy Frameworks", set the "Destination" to "Frameworks", and add `ColiseuPlayer.framework`.

---

## Usage

### Assign to Remote player

Working on Demo

```swift
import ColiseuPlayer
````

## Contact

Follow Coliseu on Twitter ([@coliseuapp](https://twitter.com/coliseuapp))

### Creator

- [Ricardo Pereira](http://github.com/ricardopereira) ([@ricardopereiraw](https://twitter.com/ricardopereiraw))

## License

ColiseuPlayer is released under the MIT license. See LICENSE for details.
