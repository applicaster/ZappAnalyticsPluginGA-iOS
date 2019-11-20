Pod::Spec.new do |s|
  s.name  = "__framework_name__"
  s.version = '__version__'
  s.summary = "__framework_name__"
  s.description = "__framework_name__ container."
  s.homepage  = "https://github.com/applicaster/__framework_name__-iOS"
  s.license = 'CMPS'
  s.author = { "cmps" => "Applicaster LTD." }
  s.source  = { :git => "git@github.com:applicaster/__framework_name__-iOS.git", :tag => s.version.to_s }
  s.requires_arc = true
  s.static_framework = true
  s.platform = :ios
  s.ios.deployment_target = '__ios_platform_version__'

  s.public_header_files = '**/*.h'

  s.source_files = '__framework_name__/**/*.{h,m,swift}'

  s.frameworks = 'AdSupport', 'CoreData', 'SystemConfiguration'
  s.libraries = 'sqlite3.0', 'z'

  s.resources = [
                "**/*.xcassets",
                "**/*.storyboard",
                "**/*.xib",
                "**/*.png"]

  s.preserve_paths = ['__framework_name__/module-ci/module.modulemap']

  s.xcconfig =  { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
                    'OTHER_LDFLAGS' => '$(inherited) -l"GoogleAnalytics"',
                    'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**',
                    'ENABLE_BITCODE' => 'YES',
                    'SWIFT_VERSION' => '__swift_version__'
              }

  s.dependency 'ZappAnalyticsPluginsSDK', '~> 10.0.0'
  s.ios.dependency 'GoogleAnalytics', '~> 3.17.0'

  s.ios.script_phase = {
    :name => 'Copy modulemap',
    :script =>  <<~SCRIPT,
                  rm -f "${PODS_ROOT}/Headers/Public/GoogleAnalytics/module.modulemap"
                  cp "${PODS_TARGET_SRCROOT}/__framework_name__/module-ci/module.modulemap" "${PODS_ROOT}/Headers/Public/GoogleAnalytics/module.modulemap"
                SCRIPT
    :execution_position => :before_compile }

end
