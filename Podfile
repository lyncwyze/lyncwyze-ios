# Uncomment the next line to define a global platform for your project
platform :ios, '16.6'

target 'LyncWyze' do
  use_frameworks!
  inhibit_all_warnings!

  # Firebase
  pod 'Firebase/Core', '~> 11.9.0'
  pod 'Firebase/Messaging', '~> 11.9.0'

  # Add dependencies here
  pod 'SwiftDate', '~> 7.0'
  pod 'DateToolsSwift', '~> 5.0'
  pod 'PhoneNumberKit', '~> 3.6'
  
  # Pods for LyncWyze
  target 'LyncWyzeTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'LyncWyzeUITests' do
    # Pods for testing
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.6'
      # For Apple Silicon
      if config.build_settings['PLATFORM_NAME'] == 'iphonesimulator'
        config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
      end
      # Fix for Xcode 15 warnings
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
