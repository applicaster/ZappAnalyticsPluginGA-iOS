Pod::Spec.new do |s|
  s.name  = "__framework_name__"
  s.version = '__version__'
  s.platform  = :ios, '__ios_platform_version__'
  s.summary = "__framework_name__"
  s.description = "__framework_name__ container."
  s.homepage  = "https://github.com/applicaster/__framework_name__-iOS"
  s.license = 'CMPS'
	s.author = "Applicaster LTD."
	s.source = {
      "http" => "__source_url__"
  }

  s.requires_arc = true
  s.static_framework = true
  s.vendored_frameworks = '__framework_name__.framework'

  # base dependency
  s.dependency 'ZappAnalyticsPluginsSDK'

  # frameworks
  s.frameworks = 'AdSupport', 'CoreData', 'SystemConfiguration'
  s.libraries = 'sqlite3.0', 'z'

  # config
  s.xcconfig =  { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
                  'OTHER_LDFLAGS' => '$(inherited) -l"GoogleAnalytics"',
                  'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**',
                  'ENABLE_BITCODE' => 'YES',
                  'SWIFT_VERSION' => '__swift_version__'
              }

  # addtional dependencies
  s.dependency 'GoogleAnalytics', '~> 3.17.0'
end
