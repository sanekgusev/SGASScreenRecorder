#
# Be sure to run `pod lib lint SGASScreenRecorder.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "SGASScreenRecorder"
  s.version          = "1.0.0"
  s.summary          = "A short description of SGASScreenRecorder."
  s.description      = <<-DESC
                       An optional longer description of SGASScreenRecorder

                       * Markdown format.
                       * Don't worry about the indent, we strip it!
                       DESC
  s.homepage         = "https://github.com/sanekgusev/SGASScreenRecorder"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Alexander Gusev" => "sanekgusev@gmail.com" }
  s.source           = { :git => "https://github.com/sanekgusev/SGASScreenRecorder.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/sanekgusev'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.subspec 'SGASPhotoLibraryScreenRecorder' do |pls|
    pls.source_files = 'Pod/Classes/SGASPhotoLibraryScreenRecorder.{h,m}'
    pls.frameworks = 'AssetsLibrary'
    pls.subspec 'SGASScreenRecorder' do |srs|
      srs.source_files = 'Pod/Classes/SGASScreenRecorder.{h,m}', 'Pod/Classes/SGASScreenRecorderSettings.{h,m}'
      srs.dependency 'SGVBackgroundRunloop', '~> 1.0'
      srs.frameworks = 'UIKit', 'AVFoundation', 'CoreMedia'
      srs.subspec 'SGASScreenRecorderPrivateHeaders' do |phs|
      	phs.source_files = 'Pod/PrivateHeaders/**/*.h'
      	phs.private_header_files = 'Pod/PrivateHeaders/**/*.h'
      	phs.header_mappings_dir = 'Pod/PrivateHeaders'
      end
    end
  end

  s.source_files = 'Pod/Classes/SGASScreenRecorderUIManager.{h,m}', 
    'Pod/Classes/SGASTouchVisualizer.{h,m}', 'Pod/Classes/SGASApplication.{h,m}',
    'Pod/Classes/Windows/*.{h,m}'
  s.public_header_files = 'Pod/Classes/SGASScreenRecorderUIManager.h'
  s.frameworks = 'UIKit'
  s.dependency 'SGVObjcMixin', '~> 1.0'

  s.xcconfig = { 

  'FRAMEWORK_SEARCH_PATHS' => '"$(SDKROOT)$(SYSTEM_LIBRARY_DIR)/PrivateFrameworks"/**',
  'OTHER_LDFLAGS[sdk=iphoneos*]' => '$(inherited) -framework IOSurface -framework IOMobileFramebuffer -framework IOKit',

  'ENABLE_STRICT_OBJC_MSGSEND' => 'YES',

  #'GCC_TREAT_WARNINGS_AS_ERRORS' => 'YES',
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
