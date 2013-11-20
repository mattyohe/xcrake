# encoding: UTF-8

# Copyright (c) 2013 WillowTree Apps
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Thanks to @tperfitt (Timothy Perfitt) for his write-up on re-signining iOS apps
# http://www.afp548.com/2012/06/05/re-signining-ios-apps/

require 'yaml'
require 'plist'
require 'openssl'
require 'rest-client'

def cert_valid?(common_name, sha1)
  certs = `security find-certificate -c "#{common_name}" -Z -p -a`
  end_certificate = "-----END CERTIFICATE-----"
  state = :searching
  cert = ""

  certs.lines.each do |line|
    case state
      when :searching
 
        if line.include? sha1
          state = :found_hash
        end
 
      when :found_hash
        cert << line
      if line.include? end_certificate
        state = :did_end
      end
      when :did_end
    end
  end

  if cert.empty?
    throw 'Failed to find Signing Certificate'
  end

  File.open("#{@build_path}/pem", 'w') {|f| f.write(cert) }
  system("security verify-cert -c \"#{@build_path}/pem\"")
  File.unlink("#{@build_path}/pem")
  return $?.success?
end

# Gets build settings from xcodebuild given a build from the config
def get_build_settings(build)
  hash = Hash.new
  build_settings = `xcodebuild -showBuildSettings -scheme \"#{build['scheme']}\" -configuration \"#{build['configuration']}\"`.strip
  build_settings.each_line do |line|
    if line[0] == ' '
      key_value = line.split(' = ')
      key = key_value[0]
      value = key_value[1]
      value = value[0..-2]

      key = key[4..-1]
      if hash[key].nil?
        hash[key] = value
      end
    end
  end
  return hash
end

def self.unwrap_signed_data(signed_data)
  pkcs7 = OpenSSL::PKCS7.new(signed_data)
  store = OpenSSL::X509::Store.new
  flags = OpenSSL::PKCS7::NOVERIFY
  pkcs7.verify([], store, nil, flags) # VERIFY IT SO WE CAN PULL OUT THE DATA
  return pkcs7.data
end

def subject_from_cert(in_cert)
  certificate=OpenSSL::X509::Certificate.new in_cert
  subject=certificate.subject.to_s

  subject=subject[/CN=.*?\//].sub!('CN=', '').sub("\/", '')
  return subject
end

def parse_provisioning_proflie(path)
  # Read provisioning profile into signedData
  signed_data=File.read(path)
  # Parse profile
  r = Plist::parse_xml(unwrap_signed_data(signed_data))
  return r
end

def install_provisioning_profile_if_needed(path)
  r = parse_provisioning_proflie(path)
  uuid = r['UUID']
  file_path = "#{ENV['HOME']}/Library/MobileDevice/Provisioning\ Profiles/#{uuid}.mobileprovision"
  unless File.exists?(file_path)
    FileUtils.cp_r(path, file_path)
  end
end

def check_new_version

  begin
    response = RestClient::Request.execute(
      :method => :get,
      :url => "https://api.github.com/repos/willowtreeapps/xcrake/releases",
      :timeout => 5,
      :open_timeout => 5,
      :accept => :json
    )
  rescue => e
    response = e.response
  end

  if response && ((response.code == 201) || (response.code == 200))
    
    releases = JSON.parse(response)
    new_releases = releases.select do |release| 
      release['tag_name'] > @xcrake_version
    end
    if new_releases.size > 0
      new_releases.sort! { |a,b| a['tag_name'] <=> b['tag_name'] }
      puts "xcrake version #{new_releases.reverse[0]['tag_name']} is out!"
    end
  end
end

@xcrake_version = '1.0.1b2'
puts "xcrake version: #{@xcrake_version}"

check_new_version

default_tasks = %w(clean pod:clean) # Dependencies for the default rake task

# Check for the xcrake.config file. If it exists, load it up. Otherwise we make @config
# into an empty hash with an empty 'builds' set. This lets us to some better error checking and
# give instructions to the user.
if File.exists?('xcrake.config')
  @config = YAML.load_file('xcrake.config') # Load the YAML config file
else
  @config = Hash['builds' => []] # Create an empty config if we don't have the file
  unless Rake.application.top_level_tasks.include? 'config:create'
    # if we don't have internal config, and we're not creating one, give the user some instruction
    puts 'xcrake.config file required. Run rake config:create to generate a template'
  end
end

@artifacts_path = @config['artifacts_path'].nil? ? 'artifacts' : @config['artifacts_path']
@build_path = @config['build_path'].nil? ? '.xcrake' : @config['build_path']
@profiles_path = @config['profiles_path'].nil? ? 'profiles' : @config['profiles_path']
@build_tool = @config['build_tool'].nil? ? 'xcodebuild' : @config['build_tool']

app_build_dependencies = [@artifacts_path, @build_path] # Dependencies for .apps

# Building each build is a default dependancy
# should be refactored to build once and resign
@config['builds'].each do |build|
  default_tasks << "#{@artifacts_path}/" + build['name'] + '.ipa'
end

scheme_configurations = Array.new
added_scheme_configurations = Array.new
@config['builds'].each do |build|
  scheme_configuration = "#{build['scheme']}-#{build['configuration']}"
  unless added_scheme_configurations.include? scheme_configuration
    scheme_configurations << build
    added_scheme_configurations << scheme_configuration
    default_tasks << "#{@artifacts_path}/#{build['scheme']}-#{build['configuration']}.app"
  end
end

# perform default_tasks if no specific task is given.
task :default => default_tasks do
end

# Removes build folder and invokes pod:clean
desc 'Cleans build folder'
task 'clean' => %w(pod:clean) do
  FileUtils.rm_rf("#{@build_path}/")
  FileUtils.rm_rf("#{@artifacts_path}/")
end

# Creates the build folder
desc 'Create build output folder'
directory @build_path

# Creates the artifacts folder
desc 'Create artifacts output folder'
directory @artifacts_path

scheme_configurations.each do |build|
  # If we have an internal config define a task to create internal.app
  app_path = "#{@artifacts_path}/#{build['scheme']}-#{build['configuration']}.app"
  desc "Create #{app_path}"
  file app_path => app_build_dependencies do

    # Invoke pod:install if there is a Podfile
    if File.exist?('Podfile')
      Rake::Task['pod:install'].invoke
    end

    # Get settings needed to build the application
    build_settings = get_build_settings(build)
    plist_path = build_settings['INFOPLIST_FILE']
    project_name = build_settings['PROJECT_NAME']
    product_name = build_settings['PRODUCT_NAME']

    # If we have a build number append it
    build_number = ENV['BUILD_NUMBER']

    unless build_number.nil?
      # Set the bundle id in the plist to match the bundle id from the build config
      sh "/usr/libexec/PlistBuddy -c \"Set :CFBundleIdentifier #{build['bundle_id']}\" \"#{plist_path}\""

      # Get current build number
      version_number = `/usr/libexec/PlistBuddy -c \"Print :CFBundleShortVersionString\" \"#{plist_path}\"`.chomp

      values = version_number.split('.')
      while values.size < 4
        values << '0'
      end
      values[values.size - 1] = build_number
      version_number = values.join('.')
      sh "/usr/libexec/PlistBuddy -c \"Set :CFBundleVersion #{version_number}\" \"#{plist_path}\""
    end

    # Detect if project or workspace
    project_type = File.exist?("#{project_name}.xcworkspace")? 'workspace' : 'project'

    # Get project / workspace file name
    project_file_name = project_type == 'workspace'? "#{project_name}.xcworkspace" : "#{project_name}.xcodeproj"

    installed_profile_name = build['provisioning_profile']
    checked_in_profile_path = "#{@profiles_path}/#{build['provisioning_profile']}.mobileprovision"
    if File.exists?(checked_in_profile_path)
      install_provisioning_profile_if_needed(checked_in_profile_path)
      installed_profile_name = parse_provisioning_proflie(checked_in_profile_path)['uuid']
    end

    puts 'Verifying Signing Certificate'
    unless cert_valid?(build['signing_identity'], build['signing_identity_SHA1'])
      throw 'Failed to verify Signing Certificate'
    end
    puts 'Certificate Valid'

    # Perform build using build settings and config values
    build_command = "#{@build_tool} -#{project_type} \"#{project_file_name}\"\
     CONFIGURATION_BUILD_DIR=\"$PWD/#{@build_path}/#{build['scheme']}-#{build['configuration']}_build\"\
     CODE_SIGN_IDENTITY=\"#{build['signing_identity']}\"\
     PROVISIONING_PROFILE=\"#{installed_profile_name}\"\
     TARGET_TEMP_DIR=\"$PWD/#{@build_path}/#{build['scheme']}-#{build['configuration']}_build/temp\"\
     BUILT_PRODUCTS_DIR=\"$PWD/#{@build_path}/#{build['scheme']}-#{build['configuration']}_build\"\
     -scheme \"#{build['scheme']}\"\
     -configuration \"#{build['configuration']}\""

    unless @config['additional_build_options'].nil?
      build_command = "#{build_command} #{@config['additional_build_options']}"
    end

    begin
      sh build_command
    rescue Exception => e
      throw "Build command #{build_command} failed: #{e}"
    end

    # Move built app into artifacts path to statisfy file dependancy
    FileUtils.cp_r("#{@build_path}/#{build['scheme']}-#{build['configuration']}_build/#{product_name}.app", app_path)

    # Zip up dsym, and move into artifacts folder
    sh "zip -qrv \"#{@artifacts_path}/#{build['scheme']}-#{build['configuration']}.app.dSYM.zip\"\
     \"#{@build_path}/#{build['scheme']}-#{build['configuration']}_build/#{product_name}.app.dSYM\""
  end
end

# For each build in the config, create a task to build the ipa (bundler/name.ipa)
@config['builds'].each do |build|

  app_path = "#{@artifacts_path}/#{build['scheme']}-#{build['configuration']}.app"

  desc "Build #{build['name']}"
  file "#{@artifacts_path}/#{build['name']}.ipa" =>  [app_path] do

    # Grab developer id from the config, and set path to .app
    dev_id = build['signing_identity']

    # Get path to the specified provisioning profile
    prov_profile_path = "#{ENV['HOME']}/Library/MobileDevice/Provisioning\ Profiles/#{build['provisioning_profile']}.mobileprovision"
    checked_in_profile_path = "#{@profiles_path}/#{build['provisioning_profile']}.mobileprovision"
    if File.exists?(checked_in_profile_path)
      prov_profile_path = checked_in_profile_path
    end

    # Parse profile
    r = parse_provisioning_proflie(prov_profile_path)

    # Grab entitlements
    entitlements=r['Entitlements']

    # Update info plist to have bundle id specified in the config
    info_plist_path="#{app_path}/Info.plist"
    system("plutil -convert xml1 \"#{info_plist_path}\"")
    file_data=File.read(info_plist_path)
    info_plist=Plist::parse_xml(file_data)
    info_plist['CFBundleIdentifier']=build['bundle_id']

    # Save updated info plist and entitlements plist
    info_plist.save_plist info_plist_path
    entitlements.save_plist("#{app_path}/Entitlements.plist")

    # Remove old embedded provisioning profile
    File.unlink("#{app_path}/embedded.mobileprovision") if File.exists? "#{app_path}/embedded.mobileprovision"

    # Embed new profile
    FileUtils.cp_r(prov_profile_path,"#{app_path}/embedded.mobileprovision")

    puts 'Verifying Signing Certificate'
    unless cert_valid?(build['signing_identity'], build['signing_identity_SHA1'])
      throw 'Failed to verify Signing Certificate'
    end
    puts 'Certificate Valid'

    # Resign application using correct profile and entitlements
    $stderr.puts "running /usr/bin/codesign -f -s \"#{dev_id}\" --resource-rules=\"#{app_path}/ResourceRules.plist\" \"#{app_path}\""
    result=system("/usr/bin/codesign -f -s \"#{build['signing_identity_SHA1']}\" --resource-rules=\"#{app_path}/ResourceRules.plist\" --entitlements=\"#{app_path}/Entitlements.plist\" \"#{app_path}\"")

    $stderr.puts "codesigning returned #{result}"
    throw 'Codesigning failed' if !result

    # Create temporary folder to zip up the application
    app_folder=Pathname.new(app_path).dirname.to_s
    temp_folder="#{app_folder}/temp_#{build['name']}"
    Dir.mkdir(temp_folder)
    Dir.mkdir("#{temp_folder}/Payload")
    FileUtils.cp_r(app_path,"#{temp_folder}/Payload")

    # Zip it up into the correct directory
    system("pushd \"#{temp_folder}\" && /usr/bin/zip -r \"../#{build['name']}.ipa\" Payload")

    # Remove temporary folder
    FileUtils.rm_rf(temp_folder)
  end
end
