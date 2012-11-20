guard 'rspec', :version => 2 do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }    
  watch('spec/spec_helper.rb') { "spec" }  

  #guard api changes
  watch('api/api.rb') { |m| 'spec/api'}
  watch(%r{^api/api_v(.+)\.rb}) { |m| "spec/api/api_v#{m[1]}_spec.rb"}
end

guard 'bundler' do
  watch('Gemfile')
  # Uncomment next line if Gemfile contain `gemspec' command
  # watch(/^.+\.gemspec/)
end