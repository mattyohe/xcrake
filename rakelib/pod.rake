namespace 'pod' do

  # Installs coocoapods (uses bundler if a Gemfile is found)
  desc 'Install pods in Podfile'
  task 'install' do
    if File.exist?('Gemfile')
      sh %{ bundle exec pod install }
    else
      sh %{ pod install }
    end
  end

  # Removes Pods/ directory and it's contents
  desc 'Remove Pods/ dir'
  task 'clean' do
    if File.exist?('Pods')
      FileUtils.rm_rf('Pods/')
    end
  end

end
