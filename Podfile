# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'
source 'git@github.com:CocoaPods/Specs.git'
source 'git@github.com:applicaster/CocoaPods.git'
source 'git@github.com:applicaster/CocoaPods-Private.git'

target 'ZappAnalyticsPluginGA' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for ZappAnalyticsPluginChartbeat
  pod 'ZappPlugins', '~> 6.0.12'
  pod 'ZappAnalyticsPluginsSDK', '~> 5.0.0'
  pod 'GoogleAnalytics', '~> 3.17.0'

  target 'ZappAnalyticsPluginGATests' do
    # Pods for testing
  end
end

post_install do |installer|
    system('rm -f "${PODS_ROOT}/Headers/Public/GoogleAnalytics/module.modulemap"')
    system('cp "ZappAnalyticsPluginGA/module-ci/module.modulemap" "Pods/Headers/Public/GoogleAnalytics/module.modulemap"')
end
