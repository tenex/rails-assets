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
  require File.expand_path("lib/bower/build", File.dirname(__FILE__), )
  Bower::Convert.new(pkg).build!(:debug) do |file|
    fname = File.basename(file)
    File.open(fname, "w"){|f| f.write File.read(file) }
    system "gem unpack #{fname}"
  end
end
