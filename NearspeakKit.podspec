Pod::Spec.new do |s|
  s.name         = "NearspeakKit"
  s.version      = "1.0.0"
  s.summary      = "The iOS SDK for Nearspeak."
  s.homepage     = "http://www.nearspeak.at"
  s.license      = { :type => "LGPL", :file => "LICENSE" }
  s.author             = { "Patrick" => "patrick.steiner@mopius.com" }

  s.requires_arc = true
  s.ios.deployment_target = "8.0"
  s.source       = { :git => "http://intern.appaya.at/nearspeak/nearspeakkit-ios.git", :tag => "1.0.0" }
  s.source_files  = "NearspeakKit/*.swift"
  s.dependency "SwiftyJSON", ">= 2.2"
end
