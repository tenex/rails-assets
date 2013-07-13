require "erb"

module Rails
  module Assets
    class Builder
      include Utils
      attr_accessor :build_dir, :bower_root, :gem_root,
                    :log, :component

      def initialize(build_dir, bower_name, log)
        @build_dir = build_dir
        @log = log
        @component = Component.new(bower_name)
        @bower_root = File.join(@build_dir, "bower_components", @component.name)
        @gem_root = File.join(@build_dir, @component.gem_name)
      end

      def build!(opts = {})
        log.info "Building gem #{component.gem_name} form #{component.full} package"

        update_component_info

        if !opts[:force] && index.exists?(component) # skip building if gem has been already buit by other worker
          log.info "Gem #{component.gem_name} already built"
          nil
        else
          process_javascript_files
          process_css_and_image_files
          generate_gem_structure
          build_gem

          component.tmpfile = gem_pkg
          component
        end
      end

      def index
        @index ||= Index.new
      end

      def update_component_info
        component.version = info[:version].to_s.strip
        raise BuildError.new("Version is empty") if component.version == ""
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
        @js_root ||= File.join("vendor", "assets", "javascripts")
      end

      def css_root
        @css_root ||= File.join("vendor", "assets", "stylesheets")
      end

      def images_root
        @images_root ||= File.join("vendor", "assets", "images")
      end

      def gem_pkg
        @gem_pkg ||= File.join(gem_root, "pkg", "#{gem_name}-#{info[:version]}.gem")
      end

      def gem_name
        component.gem_name
      end

      def gem_module
        "#{GEM_PREFIX}#{component.name.gsub(/\./, "_")}".split("-").map {|e| e.capitalize}.join
      end

      def gem_files
        @gem_files ||= []
      end

      def gem_dependencies
        (info[:dependencies] || []).map do |dep, version|
          version.gsub!(/~(\d)/, '~> \1')
          ["#{GEM_PREFIX}#{dep}", version]
        end
      end

      def gem_homepage
        if repo = info[:repository]
          if url = repo["url"]
            case url
            when %r|git://github.com/(.+)/(.+).git|
              "http://github.com/#{$1}/#{$2}"
            end
          end
        end
      end

      def generate_gem_file(file)
        source_path = File.join(templates_dir, file)
        file.gsub!("GEM", component.gem_name)
        erb = file.sub!(/\.erb$/, "")
        target_path = File.join(gem_root, file)

        FileUtils.mkdir_p File.dirname(target_path)
        FileUtils.cp source_path, target_path

        gem_files << file

        if erb
          File.open(target_path, "w") do |f|
            erb = ERB.new(File.read(source_path))
            erb.filename = source_path
            f.write erb.result(binding)
          end
        end

        puts "--> Generated #{target_path}"
      end

      def generate_gem_structure
        generate_gem_file "lib/GEM/version.rb.erb"
        generate_gem_file "lib/GEM.rb.erb"
        generate_gem_file "Gemfile"
        generate_gem_file "Rakefile"
        generate_gem_file "README.md.erb"

        # This must be the last one so that is can have full gem_files list
        generate_gem_file "GEM.gemspec.erb"
      end

      def templates_dir
        File.expand_path("../templates", __FILE__)
      end

      def process_javascript_files
        raise BuildError.new("Missing main js file") if info[:javascripts].empty?

        FileUtils.mkdir_p File.join(gem_root, js_root)

        files = info[:javascripts].map do |js|
          log.info "Processing #{js}"
          filename = File.basename(js)

          log.info "Copying #{js} to #{filename}"
          FileUtils.cp File.join(bower_root, js), File.join(gem_root, js_root, filename)
          gem_files << File.join(js_root, filename)

          filename
        end

        # Create manifest file if needed
        manifest = "#{component.name}.js"
        unless files.find {|f| f == manifest }
          File.open(File.join(gem_root, js_root, manifest), "w") do |f|
            files.each do |filename|
              filename_no_ext = filename.gsub(/\.js$/, "")
              f.puts "//= require #{filename_no_ext}"
            end
          end
          gem_files << File.join(js_root, manifest)
        end
      end

      # This one is tricky
      # bower.json does not include css/images
      # so we will try to be a little bit smart here
      def process_css_and_image_files
        images = find_and_copy_files(images_root, "{png,gif,jpg,jpeg}")
        css = find_and_copy_files(css_root, "css")

        log.debug "images: "
        log.debug images
        log.debug "css: "
        log.debug css

        # Replace image paths in css files
        css.each do |css_name, css_file|
          replaced = file_replace File.join(gem_root, css_file[:new_path]) do |f|
            images.each do |image_name, image_file|
              f.call image_file[:old_relative_path],
                      %Q|<%= asset_path "#{image_name}" %>|
            end
          end

          if replaced
            op = css_file[:new_path]
            np = css_file[:new_path] + ".erb"
            FileUtils.mv File.join(gem_root, op), File.join(gem_root, np)
            gem_files.delete(op)
            gem_files << (np)
          end
        end
      end

      def find_and_copy_files(root, ext)
        FileUtils.mkdir_p File.join(gem_root, root)
        info[:javascripts].inject({}) do |hash, js|
          dir = File.join(bower_root, File.dirname(js))

          log.info "Searching #{dir} for #{ext} files"
          Dir["#{dir}/**/*.#{ext}"].each do |f|
            filename = File.basename(f)
            log.info "Copying #{f} to #{filename}"
            FileUtils.cp f, File.join(gem_root, root, filename)
            hash[filename] = {
              :old_relative_path => f.sub(/^#{dir}\//, ""),
              :new_path => File.join(root, filename)
            }
            gem_files << File.join(root, filename)
          end

          hash
        end
      end

      def build_gem
        sh gem_root, RAKE_BIN, "build"
      end
    end
  end
end
