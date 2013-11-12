namespace 'testflight' do

  desc 'Upload all builds to TestFlight'
  multitask 'all' => @config['builds'].collect { |build| build['testflight_team_token']? "testflight:#{build['name']}" : nil }.compact do
  end

  @config['builds'].collect { |build| build['testflight_team_token']? build : nil }.compact.each do |build|
    desc "Upload #{build['name']} to TestFlight"
    task "#{build['name']}" => ["#{@artifacts_path}/#{build['name']}.ipa"] do

      #inspired by https://github.com/milesmatthias/testflight_upload/blob/master/lib/testflight_upload.rb
      payload = {
        :api_token => build['testflight_api_token'],
        :team_token => build['testflight_team_token'],
        :file => File.new("#{@artifacts_path}/#{build['name']}.ipa", 'rb'),
        :notes => build['testflight_notes'] || 'New build!',
        :distribution_lists => build['testflight_distribution_lists'] || '',
        :notify => build['testflight_notify'] || false,
        :dsym => File.new("#{@artifacts_path}/#{build['scheme']}-#{build['configuration']}.app.dSYM.zip", 'rb')
      }

      puts 'Uploading to TestFlight'

      begin
        response = RestClient.post("https://testflightapp.com/api/builds.json", payload, :accept => :json)
        puts "response = ", response
      rescue => e
        response = e.response
      end

      if (response.code == 201) || (response.code == 200)
        puts "Upload complete."
      else
        throw "TestFlight upload failed: (#{response})"
      end
    end
  end

end