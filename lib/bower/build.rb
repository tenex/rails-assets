require "tmpdir"
require "json"
require "fileutils"

module Bower
  BOWER_BIN = "/usr/local/share/npm/bin/bower"
  BUNDLE_BIN = "bundle"
  GIT_BIN = "git"
  RAKE_BIN = "rake"
  BOWER_MANIFESTS = ["bower.json", "package.json", "component.json"]

  class Build
    attr_accessor :bower_name, :bower_root, :gem_name, :gem_root

    def initialize(gemname)
      name = gemname.gsub(/^rails-assets-/, "")

      @bower_name = name
      @bower_root = "bower_components/#{@bower_name}"
      @gem_name = gemname
      @gem_root = @gem_name
    end

    def build!
      puts "--> Building gem #{gem_name} form #{bower_name} package"

      # Dir.mktmpdir do |dir|
      dir = "/tmp/build"
      sh "rm -rf #{dir}"
      sh "mkdir -p #{dir}"
        Dir.chdir(dir) do
          bower_install
          bundle_gem
          process_version_file
          process_gemspec_file
          process_rails_engine
          fix_ruby_require
          process_javascript_files
          build_gem
        end
        yield File.join(dir, gem_pkg)
      # end

    end

    def info
      @info ||= begin
        BOWER_MANIFESTS
          .map {|f| File.join(bower_root, f) }
          .select {|f| File.exists?(f) }
          .map {|f| read_bower_file(f) }
          .inject({}){|h,e| h.merge(e) }
      end
    end

    def js_root
      @js_root ||= File.join(gem_root, "vendor", "assets", "javascripts")
    end

    def gem_pkg
      @gem_pkg ||= File.join(gem_root, "pkg", "#{gem_name}-#{info[:version]}.gem")
    end

    def gem_lib_paths
      @gem_lib_root ||= begin
        puts "--> gem_name #{gem_name}"
        root = File.join(gem_root, "lib", gem_name)
        puts "--> root #{root}"
        if File.exist?(root)
          [
            root,
            "#{root}.rb"
          ]
        else
          chunks = gem_name.split("-")
          last = chunks.pop
          [
            File.join(gem_root, "lib", *(chunks + [last])),
            File.join(gem_root, "lib", *chunks, "#{last}.rb"),
            root,
            File.join(*chunks, last)
          ]
        end
      end
    end

    def gem_lib_main
      gem_lib_paths[1]
    end

    def gem_lib(file)
      File.join(gem_lib_paths[0], file)
    end

    def fix_ruby_require
      puts "--> gem_lib_paths #{gem_lib_paths.inspect}"
      if root = gem_lib_paths[2]
        puts "--> Creating missing #{root}.rb file"
        File.open("#{root}.rb", "w") do |f|
          f.puts %Q|require "#{gem_lib_paths[3]}"|
        end
      end
    end

    def process_version_file
      file_replace gem_lib("version.rb") do |f|
        f.call  %Q{VERSION = "0.0.1"}, %Q{VERSION = "#{info[:version]}"}
      end
    end

    def bower_install
      sh BOWER_BIN, "install", @bower_name
    end

    def bundle_gem
      sh BUNDLE_BIN, "gem", @gem_name
    end

    def process_gemspec_file
      file_replace File.join(gem_root, "#{gem_name}.gemspec") do |f|
        ["spec", "gem"].each do |key|
          f.call  /#{key}.authors.+/,      %Q|#{key}.authors       = [""]|
          f.call  /#{key}.email.+/,        %Q|#{key}.email         = [""]|
          f.call  /#{key}.description.+/,  %Q|#{key}.description   = %q{#{info[:description]}}|
          f.call  /#{key}.summary.+/,      %Q|#{key}.summary       = %q{#{info[:description]}}|
        end
      end
    end

    def process_rails_engine
      file_replace gem_lib_main do |f|
        f.call /^.+Your code goes here.+$/, <<-EOS
        class Engine < ::Rails::Engine
          # Rails -> use vendor directory.
        end
        EOS
      end
    end

    def process_javascript_files
      FileUtils.mkdir_p js_root

      info[:javascripts].each do |js|
        puts "--> Processing #{js}"

        filename = "__original__#{bower_name}__#{File.basename(js)}"
        filename_no_ext = filename.gsub(/\.js$/, "")

        puts "--> Copy #{js} -> #{filename}"
        FileUtils.cp File.join(bower_root, js), File.join(js_root, filename)

        # Create manifest file
        manifest = "#{bower_name}.js"
        File.open(File.join(js_root, manifest), "w") do |f|
          f.puts "//= require #{filename_no_ext}"
        end
      end
    end

    def build_gem
      Dir.chdir(gem_root) do
        sh GIT_BIN, "add", "."
        sh RAKE_BIN, "build"
      end
    end

    def publish
      # sh "gem inabox #{gemname}/#{gempkg} --host #{GEMINABOX_HOST}"
    end

    def sh(*cmd)
      puts "--> $ #{cmd.join(" ")}"
      system *cmd
    end

    def file_replace(file, &block)
      puts "--> Modifing file #{file}"
      content = File.read(file)

      proc = lambda do |source, target|
        content.gsub!(source, target)
      end

      block.call(proc)

      File.open(file, "w") do |f|
        f.write content
      end
    end

    def read_bower_file(path)
      puts "--> Reading bower file #{path}"
      data = JSON.parse(File.read(path))
      dir = File.dirname(path)

      {
        :version => data["version"],
        :description => data["description"],
        :javascripts => [data["main"]],
        :dependencies => data["dependencies"],
        :readmeFilename => data["readmeFilename"] || "README",
        :readme => data["readmeFilename"] ? File.read(File.join(dir, data["readmeFilename"])) : data["readme"]
      }.reject {|k,v| !v}
    end
  end
end
