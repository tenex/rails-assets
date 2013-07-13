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
task :convert, [:pkg] => :env do |t, args|
  pkg = args[:pkg]



  include Rails::Assets

  if component = Convert.new(Component.new(pkg)).convert!(:io => STDOUT, :debug => true, :force => true)
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

desc "Rebuild all"
task :rebuild => :env do
  index = Index.new

  index.all.each do |gem_name|
    pkg = gem_name.sub(GEM_PREFIX, "")
    index.versions(gem_name).each do |version|
      component = Component.new("#{pkg}##{version}")
      Convert.new(component).convert!(:force => true)
    end
  end
end

desc "Reindex all gems"
task :reindex => :env do
  Reindex.new.perform(:force)
end

task :env do
  $:.unshift(File.expand_path("../lib", __FILE__))
  require "rails/assets"
  include Rails::Assets
end
