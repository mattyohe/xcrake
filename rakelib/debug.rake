namespace 'debug' do

  desc 'Prints shell environment variables'
  task 'print_environment' do
    puts ENV.inspect
  end

end
