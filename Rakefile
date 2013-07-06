require "rubygems"
require "rubygems/package_task"

Gem::PackageTask.new(eval(File.read("geminabox.gemspec"))) do |pkg|
end

desc 'Clear out generated packages'
task :clean => [:clobber_package]

require 'rake/testtask'

Rake::TestTask.new("test:integration") do |t|
  t.libs << "test" << "lib"
  t.pattern = "test/integration/**/*_test.rb"
end

Rake::TestTask.new("test:smoke:paranoid") do |t|
  t.libs << "test" << "lib"
  t.pattern = "test/smoke_test.rb"
end

desc "Run the smoke tests, faster."
task "test:smoke" do
  $:.unshift("lib").unshift("test")
  require "smoke_test"
end

Rake::TestTask.new("test:requests") do |t|
  t.libs << "test" << "lib"
  t.pattern = "test/requests/**/*_test.rb"
end

Rake::TestTask.new("test:units") do |t|
  t.libs << "test" << "lib"
  t.pattern = "test/units/**/*_test.rb"
end

task :st => "test:smoke"
task :test => ["test:units", "test:requests", "test:integration"]
task :default => :test

desc "Convert bower package to gem. Run with rake convert[bower-lib-name]"
task :convert, :name do |t, args|
  name = args[:name]
  require File.expand_path("lib/bower/build", File.dirname(__FILE__), )
  Bower::Convert.new("rails-assets-#{name}").build!(:debug) do |file|
    fname = File.basename(file)
    File.open(fname, "w"){|f| f.write File.read(file) }
    system "gem unpack #{fname}"
  end
end
