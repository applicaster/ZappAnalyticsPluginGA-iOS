# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'
source 'git@github.com:CocoaPods/Specs.git'
source 'git@github.com:applicaster/CocoaPods.git'
source 'git@github.com:applicaster/CocoaPods-Private.git'

target 'ZappAnalyticsPluginGA' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for ZappAnalyticsPluginChartbeat
  # pod 'ZappPlugins', :git => 'git@github.com:applicaster/ZappPlugins-iOS.git', :branch => 'master'
  # pod 'ZappAnalyticsPluginsSDK', :git => 'git@github.com:applicaster/ZappAnalyticsPluginsSDK-iOS.git', :branch => 'master'
  pod 'ZappPlugins', '~> 10.0.0'
  pod 'ZappAnalyticsPluginsSDK', '~> 9.0.0'

  pod 'GoogleAnalytics', '~> 3.17.0'

  target 'ZappAnalyticsPluginGATests' do
    # Pods for testing
  end
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            # This works around a unit test issue introduced in Xcode 10.
            # We only apply it to the Debug configuration to avoid bloating the app size
            if config.name == "Debug" && defined?(target.product_type) && target.product_type == "com.apple.product-type.framework"
                config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = "YES"
            end
        end
    end

    system('rm -f "${PODS_ROOT}/Headers/Public/GoogleAnalytics/module.modulemap"')
    system('cp "ZappAnalyticsPluginGA/module-ci/module.modulemap" "Pods/Headers/Public/GoogleAnalytics/module.modulemap"')
end
