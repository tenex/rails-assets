require "rubygems"
require "rubygems/package_task"

Gem::PackageTask.new(eval(File.read("geminabox.gemspec"))) do |pkg|
end
task :gem => :package

desc 'Clear out generated packages'
task :clean => [:clobber_package]

require 'rake/testtask'

Rake::TestTask.new("test:integration") do |t|
  t.libs << "test" << "lib"
  t.pattern = "test/integration/**/*_test.rb"
end

task :test => "test:integration"
task :default => :test
