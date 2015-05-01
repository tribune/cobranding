require 'bundler/gem_tasks'
require 'bundler/setup'
require 'pathname'

# Note: if you get this error: "Bundler could not find compatible versions for gem ..."
# try deleting Gemfile.lock (usually happens when switching branches).

task default: :appraise_all

task :appraise_all do
  success_map = {}
  Pathname.glob('gemfiles/*.gemfile').each do |f|
    appraise_def = f.basename('.gemfile').to_s
    success = system('appraisal', appraise_def, 'rspec', 'spec')
    success_map[appraise_def] = success
  end
  puts "\n===== Test Summary ====="
  success_map.each do |appraise_def, success|
    puts "#{appraise_def}: #{success ? 'no failures (but check pending)' : 'failed'}"
  end
end
