require "rubygems"
require "rake/gempackagetask"
require "rake/rdoctask"

task :default => :package

Rake::GemPackageTask.new(eval(File.read("geminabox.gemspec"))) do |pkg|
end

Rake::RDocTask.new do |rd|
  rd.main = "README.markdown"
  rd.rdoc_files.include("README.markdown", "lib/**/*.rb")
  rd.rdoc_dir = "rdoc"
end

desc 'Clear out RDoc and generated packages'
task :clean => [:clobber_rdoc, :clobber_package]
