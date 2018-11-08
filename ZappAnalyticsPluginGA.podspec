Pod::Spec.new do |s|
  s.name             = "ZappAnalyticsPluginGA"
  s.version = '6.1.3'
  s.summary          = "ZappAnalyticsPluginGA"
  s.description      = <<-DESC
                        ZappAnalyticsPluginGA container.
                       DESC
  s.homepage         = "https://github.com/applicaster/ZappAnalyticsPlugins-iOS"
  s.license          = 'CMPS'
  s.author           = { "cmps" => "a.zchut@applicaster.com" }
  s.source           = { :git => "git@github.com:applicaster/ZappAnalyticsPlugins-iOS.git", :tag => s.version.to_s }

  s.platform     = :ios, '9.0'
  s.requires_arc = true
  s.static_framework = true

  s.source_files = 'ZappAnalyticsPluginGA/**/*.{h,m,swift}','ZappAnalyticsPluginGA/module-dev/module.modulemap'

  s.frameworks = 'AdSupport', 'CoreData', 'SystemConfiguration'
  s.libraries = 'sqlite3.0', 'z'

  s.resources = [
    "**/*.xcassets",
    "**/*.xcassets",
    "**/*.storyboard",
    "**/*.xib",
    "**/*.png"
  ]

  s.xcconfig =  {
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
    'OTHER_LDFLAGS' => '$(inherited) -l"GoogleAnalytics"',
    'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**',
    'ENABLE_BITCODE' => 'YES',
    'SWIFT_INCLUDE_PATHS' => '${PODS_TARGET_SRCROOT}/ZappAnalyticsPluginGA/module-dev',
    'SWIFT_VERSION' => '4.2'
  } 
  
  s.dependency 'ZappAnalyticsPluginsSDK'
  s.dependency 'GoogleAnalytics', '~> 3.17.0'
end
