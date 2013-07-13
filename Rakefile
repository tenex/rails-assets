require "rubygems"
require "bundler/setup"

require 'rake/testtask'

Rake::TestTask.new("test:units") do |t|
  t.libs << "test" << "lib"
  t.pattern = "test/rails/**/*_test.rb"
end

task :test => ["test:units"]
task :default => :test

desc "Convert bower package to gem. Run with rake convert[name] or convert[name#version]"
task :convert, :pkg do |t, args|
  pkg = args[:pkg]

  $:.unshift(File.expand_path("../lib", __FILE__))
  require "rails/assets"

  include Rails::Assets

  if component = Convert.new(Component.new(pkg)).convert!(:id => STDOUT, :debug => true, :force => true)
    system "gem unpack #{component.gem_path}"
  end
end

desc "Wipeout all data (data dir, redis index, installed gems)"
task :wipeout do
  print "Are you sure?"
  STDIN.gets

  system "rm -rf data"
  system "gem list rails-assets | xargs gem uninstall -ax"
  system "redis-cli KEYS 'rails-assets*' | xargs redis-cli DEL"
end
