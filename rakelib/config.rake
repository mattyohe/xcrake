namespace 'config' do

  desc 'Create template xcrake.config file'
  task 'create' do
    unless File.exists?('xcrake.config')
      contents = <<-eos
builds:
  -
    name: # Name for built ipa
    scheme: # Scheme name to build
    bundle_id: # Bundle id to set in info plist
    provisioning_profile: # UUID of provisioning profile to sign with
    signing_identity: # Signing identity name
    signing_identity_SHA1: # Signing identity SHA1
    configuration: # Build configuration to use
    # testflight_team_token: # Team token for TestFlight uploads
    # testflight_api_token: # API token for TestFlight uploads
    # testflight_distribution_lists: # Distribution list for TestFlight uploads
    # testflight_notify: # true or false
    # testflight_notes: # release notes
# artifacts_path: # Custom path for built ipa / app / dsym files
# build_path: # Custom path for temporary build files
# profiles_path: # Custom path for provisioning profiles
# build_tool: # Custom build tool to use (for example xctool)
# additional_build_options: # Options to be used during build
      eos
      File.open('xcrake.config', 'w') do |f|
        f.write(contents)
      end

      puts 'xcrake.config file created. Please edit to your needs.'

    end
  end

end
