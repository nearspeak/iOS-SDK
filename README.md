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
pod "NearspeakKit", :git => "https://github.com/nearspeak/iOS-SDK.git"
```

Note that CocoaPods version >= 36 is required and iOS deployment target >= 8.0
```bash
[sudo] gem install cocoapods -v ">=0.36"
```

## Usage

To discover iBeacon Nearspeak tags your app requires the following keys setup in your `Info.plist`:
* NSLocationAlwaysUsageDescription
* UIBackgroundModes: [bluetooth-central, location]

In your Swift Class `import NearspeakKit` to use the NearspeakKit

### Start discovering for Nearspeak beacons

Start listening to tag update notifications.
`
NSNotificationCenter.defaultCenter().addObserver(self, selector: "onNearbyTagsUpdatedNotification:", name: NSKConstants.managerNotificationNearbyTagsUpdatedKey, object: nil)
`

Implement a function, which gets called if one or more tags are discovered.
```swift
func onNearbyTagsUpdatedNotification(notification: NSNotification) {
  // refresh the table view
  dispatch_async(dispatch_get_main_queue(), { () -> Void in
      self.tableView.reloadData()
      print("Found \(NSKManager.sharedInstance.nearbyTags.count) tags")
    })
}
```

You can access the nearby tags array via `NSKManager.sharedInstance.nearbyTags`.

Now start the beacon discovery.

`NSKManager.sharedInstance.startBeaconDiscovery(true)`
