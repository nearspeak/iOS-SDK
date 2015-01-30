## Installation

_NearspeakKit is packaged as a Swift framework. Currently this is the simplest way to add it to your app:_

1. Drag `NearspeakKit.xcodeproj` to your project in the _Project Navigator_.
2. Select your project and then your app target. Open the _Build Phases_ panel.
3. Expand the _Target Dependencies_ group, and add `NearspeakKit.framework`.
4. Click on the `+` button at the top left of the panel and select _New Copy Files Phase_. Set _Destination_ to _Frameworks_, and add `NearspeakKit.framework`.
5. `import NearspeakKit` whenever you want to use NearspeakKit.



1. Drag `NearspeakKit.xcodeproj` to your project in the _Project Navigator_.
2. Let Xcode build a new Workspace file.
3. Select your project and then your app target. Open the _General_ panel.
4. Click on the `+` button at the _Embedded Binaries_ section and add the `NearspeakKit.framework`
5. `import NearspeakKit` whenever you want to use NearspeakKit.