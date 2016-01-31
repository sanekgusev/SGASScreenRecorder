Pod::Spec.new do |s|
  s.name             = "SGASScreenRecorder"
  s.version          = "1.0.1"
  s.summary          = "Efficient on-device screen recording for iOS apps."
  s.cocoapods_version = '>= 1.0.0.beta2'

  s.description      = <<-DESC
  					   Record whatever is happening on your device's screen while your app is in foreground.

  					   Features:

  					   * low performance impact
  					   * low memory footprint
  					   * save recordings to a video file or import into Photo Library
  					   * touch visualization during recording
  					   * simple overlay UI to start/stop recording

                       To be only used in development and in-house builds, *not* App Store-safe at all.

                       DESC
  s.homepage         = "https://github.com/sanekgusev/SGASScreenRecorder"
  s.screenshots      = "https://cloud.githubusercontent.com/assets/1178649/5689239/f76d606e-9861-11e4-9213-e048fbfe9f61.PNG"
  s.license          = 'MIT'
  s.author           = { "Alexander Gusev" => "sanekgusev@gmail.com" }
  s.source           = { :git => "https://github.com/sanekgusev/SGASScreenRecorder.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/sanekgusev'

  s.ios.deployment_target = '7.0'

  s.subspec 'SGASScreenRecorder' do |srs|
    srs.source_files = 'Pod/Classes/SGASScreenRecorder.{h,m}', 'Pod/Classes/SGASScreenRecorderSettings.{h,m}'
    srs.public_header_files = 'Pod/Classes/SGASScreenRecorder.h', 'Pod/Classes/SGASScreenRecorderSettings.h'
    srs.dependency 'SGVBackgroundRunloop', '~> 1.0'
    srs.frameworks = 'UIKit', 'AVFoundation', 'CoreMedia', 'MobileCoreServices'
    srs.weak_frameworks = 'IOSurface', 'IOKit'
    srs.vendored_frameworks = 'Pod/PrivateFrameworks/8.4/IOMobileFramebuffer.framework'
    srs.preserve_paths = 'Pod/PrivateFrameworks/**/*.framework'

    srs.subspec 'SGASScreenRecorderPrivateHeaders' do |phs|
      phs.source_files = 'Pod/PrivateHeaders/**/*.h'
      phs.private_header_files = 'Pod/PrivateHeaders/**/*.h'
      phs.header_mappings_dir = 'Pod/PrivateHeaders'
      phs.preserve_paths = 'Pod/PrivateHeaders/**/*.h'
    end
  end

  s.subspec 'SGASPhotoLibraryScreenRecorder' do |pls|
    pls.source_files = 'Pod/Classes/SGASPhotoLibraryScreenRecorder.{h,m}'
    pls.frameworks = 'AssetsLibrary'
    pls.dependency 'SGASScreenRecorder/SGASScreenRecorder'
  end

  s.source_files = 'Pod/Classes/SGASScreenRecorderUIManager.{h,m}',
    'Pod/Classes/SGASTouchVisualizer.{h,m}', 'Pod/Classes/SGASTouchTrackingApplication.{h,m}', 'Pod/Classes/Windows/*.{h,m}'
  s.public_header_files = 'Pod/Classes/SGASScreenRecorderUIManager.h'
  s.frameworks = 'UIKit'
  s.dependency 'SGVObjcMixin', '~> 1.0'

  s.pod_target_xcconfig = {

  'ENABLE_STRICT_OBJC_MSGSEND' => 'YES',

  'GCC_TREAT_WARNINGS_AS_ERRORS' => 'YES',
  'GCC_WARN_FOUR_CHARACTER_CONSTANTS' => 'YES',
  'GCC_WARN_SHADOW' => 'YES',
  'GCC_WARN_64_TO_32_BIT_CONVERSION' => 'YES',
  'CLANG_WARN_IMPLICIT_SIGN_CONVERSION' => 'YES',
  'GCC_WARN_INITIALIZER_NOT_FULLY_BRACKETED' => 'YES',
  'GCC_WARN_ABOUT_MISSING_FIELD_INITIALIZERS' => 'YES',
  'GCC_WARN_ABOUT_MISSING_PROTOTYPES' => 'YES',
  'CLANG_WARN_ASSIGN_ENUM' => 'YES',
  'GCC_WARN_SIGN_COMPARE' => 'YES',
  'CLANG_WARN_SUSPICIOUS_IMPLICIT_CONVERSION' => 'YES',
  'GCC_WARN_UNKNOWN_PRAGMAS' => 'YES',
  'CLANG_WARN_UNREACHABLE_CODE' => 'YES',
  'GCC_WARN_UNUSED_LABEL' => 'YES',

  'CLANG_WARN__DUPLICATE_METHOD_MATCH' => 'YES',
  'CLANG_WARN_OBJC_IMPLICIT_ATOMIC_PROPERTIES' => 'YES',
  'CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS' => 'YES',
  'GCC_WARN_STRICT_SELECTOR_MATCH' => 'YES',

  'CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF' => 'YES',
  'CLANG_WARN_OBJC_REPEATED_USE_OF_WEAK' => 'YES',

  }

end
