Pod::Spec.new do |s|
  s.name         = "YJSimpleCamera"
  s.version      = "1.0.0"
  s.summary      = "A short  of YJSimpleCamera."
  s.description  = "A short  of YJSimpleCamera.A short  of YJSimpleCamera.A short  of YJSimpleCamera."

  s.homepage     = "https://github.com/JianiOS/YJSimpleCamera"
  s.license      = "MIT"

  s.author             = { "JianiOS" => "james123soju@sina.com" }

  s.platform     = :ios,"8.0"
  s.ios.deployment_target = "8.0"

  s.source       = { :git => "https://github.com/JianiOS/YJSimpleCamera.git", :tag => "#{s.version}" }
  s.source_files  = "Classes/*.swift"

end
