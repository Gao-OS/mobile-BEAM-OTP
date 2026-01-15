#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'beam_vm'
  s.version          = '0.1.0'
  s.summary          = 'Flutter plugin to embed the Erlang/Elixir BEAM VM'
  s.description      = <<-DESC
Flutter plugin for embedding and running the Erlang/Elixir BEAM virtual machine
on iOS devices. Requires liberlang.xcframework from mobile-BEAM-OTP releases.
                       DESC
  s.homepage         = 'https://github.com/Gao-OS/mobile-BEAM-OTP'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Gao-OS' => 'noreply@gao-os.io' }
  s.source           = { :path => '.' }

  # Source files
  s.source_files = 'Classes/**/*'

  # Dependencies
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Build settings - configure to find liberlang.xcframework in the host app
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    # Link system libraries required by liberlang
    'OTHER_LDFLAGS' => '-lz -lm -ldl -lerlang',
    # Search paths for liberlang.xcframework (provided by host app)
    # xcframework structure: ios-arm64 (device), ios-arm64_x86_64-simulator (combined simulator)
    'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}/../liberlang.xcframework/ios-arm64" "${PODS_ROOT}/../liberlang.xcframework/ios-arm64_x86_64-simulator"'
  }

  s.swift_version = '5.0'
end
