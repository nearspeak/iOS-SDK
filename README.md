# NearspeakKit for iOS

The iOS SDK for Nearspeak.

## Features

* Fetch Nearspeak tag informations from the Nearspeak server
* Query for Nearspeak iBeacons

## Requirements
- iOS 8.0+
- Xcode 6.3

## Integration

#### CocoaPods
You can use [CocoaPods](http://cocoapods.org) to install `NearspeakKit` by adding it to your `Podfile`:
```ruby
use_frameworks!
pod "NearspeakKit", :git => "http://intern.appaya.at/nearspeak/nearspeakkit-ios.git"
```

Note that CocoaPods version >= 36 is required and iOS deployment target >= 8.0
```bash
[sudo] gem install cocoapods -v '>=0.36'
```

## Usage

To discover iBeacon Nearspeak tags your app requires the following keys setup in your `Info.plist`:
* NSLocationAlwaysUsageDescription
* UIBackgroundModes: [bluetooth-central, location]

In your Swift Class `import NearspeakKit` to use the NearspeakKit

## Todo

* Add Docu
* Better error handling
* Import NSKTagManager from the Nearspeak App
* Import NSKTagStoreManager from the Nearspeak App
* Get UnitTests working again
* Switch to github repo
