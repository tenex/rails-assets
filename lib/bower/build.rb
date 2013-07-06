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
          process_css_and_image_files
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

    def css_root
      @css_root ||= File.join(gem_root, "vendor", "assets", "stylesheets")
    end

    def images_root
      @images_root ||= File.join(gem_root, "vendor", "assets", "images")
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

      files = info[:javascripts].map do |js|
        puts "--> Processing #{js}"
        # filename = "__original__#{bower_name}__#{File.basename(js)}"
        filename = File.basename(js)

        puts "--> Copy #{js} -> #{filename}"
        FileUtils.cp File.join(bower_root, js), File.join(js_root, filename)

        filename
      end

      # Create manifest file if needed
      manifest = "#{bower_name}.js"
      unless files.find {|f| f == manifest }
        File.open(File.join(js_root, manifest), "w") do |f|
          files.each do |filename|
            filename_no_ext = filename.gsub(/\.js$/, "")
            f.puts "//= require #{filename_no_ext}"
          end
        end
      end
    end

    # This one is tricky
    # bower.json does not include css/images
    # so we will try to be a little bit smart here
    def process_css_and_image_files
      images = find_and_copy_files(images_root, "{png,gif,jpg,jpeg}")
      css = find_and_copy_files(css_root, "css")

      # Replace image paths in css files
      css.each do |css_name, css_file|
        replaced = file_replace css_file[:new_path] do |f|
          images.each do |image_name, image_file|
            f.call image_file[:old_relative_path],
                    %Q|<%= asset_path "#{image_name}" %>|
          end
        end

        if replaced
          FileUtils.mv css_file[:new_path], css_file[:new_path] + ".erb"
        end
      end
    end

    def find_and_copy_files(root, ext)
      FileUtils.mkdir_p root
      info[:javascripts].inject({}) do |hash, js|
        dir = File.join(bower_root, File.dirname(js))

        puts "--> Searching #{dir} for #{ext} files"
        Dir["#{dir}/**/*.#{ext}"].map do |f|
          filename = File.basename(f)
          puts "--> Copy #{f} -> #{filename}"
          FileUtils.cp f, File.join(root, filename)
          hash[filename] = {
            :old_relative_path => f.sub(/^#{dir}\//, ""),
            :new_path => File.join(root, filename)
          }
        end

        hash
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
      content_was = content.dup

      proc = lambda do |source, target|
        content.gsub!(source, target)
      end

      block.call(proc)

      if content_was != content
        File.open(file, "w") do |f|
          f.write content
        end
        true
      else
        false
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
