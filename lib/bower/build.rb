require "tmpdir"
require "json"
require "fileutils"
require "logger"
require "open3"
require "bundler/cli"

require File.expand_path("../utils", __FILE__)
require File.expand_path("../builder", __FILE__)

module Bower
  BOWER_BIN = "bower"
  GIT_BIN = "git"
  RAKE_BIN = "rake"
  BOWER_MANIFESTS = ["bower.json", "package.json", "component.json"]

  class BuildError < Exception; end

  class Convert
    include Utils

    attr_accessor :bower_name, :bower_root, :gem_name, :gem_root,
                  :log, :build_dir

    def initialize(package)
      name = package.strip

      raise Bower::BuildError.new("Empty package name") if name.split("#").first == ""

      @bower_name = name
    end

    def build!(io = STDOUT, debug = false, &block)
      @log = Logger.new(io)
      @log.formatter = proc { |severity, datetime, progname, msg|
        "#{severity.to_s.rjust(5)} - #{msg}\n"
      }

      if debug
        dir = "/tmp/build"
        FileUtils.rm_rf(dir)
        FileUtils.mkdir_p(dir)
        build_in_dir(dir, &block)
      else
        Dir.mktmpdir do |dir|
          build_in_dir(dir, &block)
        end
      end
    end

    def build_in_dir(dir, &block)
      log.info "Building package #{bower_name} in #{dir}"
      @build_dir = dir

      bower_install

      Dir[File.join(build_dir, "bower_components", "*")].each do |f|
        name = File.basename(f)
        gem = Bower::Builder.new(@build_dir, name, log).build!
        block.call(gem)
      end
    end

    def bower_install
      sh build_dir, BOWER_BIN, "install", @bower_name
    end
  end
end
