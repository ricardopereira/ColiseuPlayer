Pod::Spec.new do |s|
  s.name             = "ColiseuPlayer"
  s.version          = "1.0.0"
  s.summary          = "Audio Player framework"
  s.homepage         = "https://github.com/ricardopereira/ColiseuPlayer"
  s.license          = 'MIT'
  s.author           = { "Ricardo Pereira" => "m@ricardopereira.eu" }
  s.source           = { :git => "https://github.com/ricardopereira/ColiseuPlayer.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/ricardopereiraw'

  s.platform     = :ios, '8.0'
  s.requires_arc = true
  s.swift_version = '5.0'

  s.source_files = 'ColiseuPlayer/*.{h,swift}'
  s.frameworks = 'AVFoundation'
end
