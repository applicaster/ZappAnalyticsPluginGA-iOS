Pod::Spec.new do |s|
  s.name             = "ZappAnalyticsPluginGA"
  s.version = '6.1.11'
  s.summary          = "ZappAnalyticsPluginGA"
  s.description      = <<-DESC
                        ZappAnalyticsPluginGA container.
                       DESC
  s.homepage         = "https://github.com/applicaster/ZappAnalyticsPluginGA-iOS"
  s.license          = 'CMPS'
  s.author           = { "cmps" => "a.zchut@applicaster.com" }
  s.source           = { :git => "git@github.com:applicaster/ZappAnalyticsPluginGA-iOS.git", :tag => s.version.to_s }
  s.platform = :ios, :tvos
  s.ios.deployment_target = "9.0"
  s.tvos.deployment_target = "10.0"

  s.requires_arc = true
  s.static_framework = true

  s.source_files = ['ZappAnalyticsPluginGA/**/*.{h,m,swift}']

  s.frameworks = 'AdSupport', 'CoreData', 'SystemConfiguration'
  s.libraries = 'sqlite3.0', 'z'

  s.resources = [
    "**/*.xcassets",
    "**/*.xcassets",
    "**/*.storyboard",
    "**/*.xib",
    "**/*.png"
  ]

  s.preserve_paths = ['ZappAnalyticsPluginGA/module-ci/module.modulemap']

  s.xcconfig =  {
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
    'ENABLE_BITCODE' => 'YES',
    'SWIFT_VERSION' => '4.2'
  }

  s.dependency 'ZappAnalyticsPluginsSDK'
  s.ios.dependency 'GoogleAnalytics'
  s.tvos.dependency 'GoogleAnalytics-tvOS'

  s.ios.script_phase = {
    :name => 'Copy modulemap',
    :script =>  <<~SCRIPT,
                  rm -f "${PODS_ROOT}/Headers/Public/GoogleAnalytics/module.modulemap"
                  cp "${PODS_TARGET_SRCROOT}/ZappAnalyticsPluginGA/module-ci/module.modulemap" "${PODS_ROOT}/Headers/Public/GoogleAnalytics/module.modulemap"
                SCRIPT
    :execution_position => :before_compile }
  s.tvos.script_phase = {
    :name => 'Copy modulemap',
    :script =>  <<~SCRIPT,
                  rm -f "${PODS_ROOT}/Headers/Public/GoogleAnalytics-tvOS/module.modulemap"
                  cp "${PODS_TARGET_SRCROOT}/ZappAnalyticsPluginGA/module-ci/module.modulemap" "${PODS_ROOT}/Headers/Public/GoogleAnalytics-tvOS/module.modulemap"
                SCRIPT
    :execution_position => :before_compile }
end
