# require "tmpdir"
# require "json"
# require "fileutils"
# require "logger"
# require "open3"
# require "bundler/cli"

class BuildError < Exception; end

class Convert
  include Utils

  attr_accessor :log, :build_dir, :opts, :component

  def initialize(component)
    @component = component
    raise BuildError.new("Empty component name") if component.name.to_s.strip == ""
  end

  def log
    @log ||= begin
      log = Logger.new(opts[:io] || STDOUT)
      log.formatter = proc { |severity, datetime, progname, msg|
        "#{severity.to_s.rjust(5)} - #{msg}\n"
      }
      log
    end
  end

  def index
    @index ||= Index.new
  end

  def file_store
    @file_store ||= FileStore.new(log)
  end

  def convert!(opts = {}, &block)
    @opts = opts

    if opts[:debug]
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
    log.info "Building package #{component.full} in #{dir}"
    @build_dir = dir

    # Sadly bower makes a mess in ~/.cache and it can't be disabled
    file_store.with_lock(file_store.bower_lock) do
      bower_install
    end

    c = Dir[File.join(build_dir, "bower_components", "*")].map do |f|
      GemBuilder.new(build_dir, File.basename(f), log).build!(@opts)
    end.compact.map do |component|
      log.info "New gem #{component.gem_name} built in #{component.tmpfile}"
      file_store.save(component)
      index.save(component)
      component
    end.find {|c| c.name == component.name }

    block.call(build_dir) if block

    c
  end

  def bower_install
    sh build_dir, BOWER_BIN, "install", "-p", component.full
  end
end
