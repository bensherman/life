task test: begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
  task :spec
rescue LoadError
  # no rspec available
end
