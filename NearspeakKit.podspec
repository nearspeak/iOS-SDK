Pod::Spec.new do |s|
  s.name         = "NearspeakKit"
  s.version      = "0.9.2"
  s.summary      = "The iOS SDK for Nearspeak."
  s.homepage     = "https://www.nearspeak.at"
  s.license      = { :type => "LGPL", :file => "LICENSE" }
  s.author       = { "Patrick" => "patrick.steiner@mopius.com" }

  s.requires_arc          = true
  s.ios.deployment_target = "8.0"
  s.source                = { :git => "https://github.com/nearspeak/iOS-SDK.git", :tag => s.version }
  s.source_files          = "NearspeakKit/*.swift"

  s.dependency "SwiftyJSON", ">= 2.2"
end
