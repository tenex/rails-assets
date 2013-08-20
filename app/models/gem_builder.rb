class GemBuilder
  EXTENSIONS = [
    [:javascripts, %w(js coffee), lambda {|files|
      files.map {|f| "//= require #{f}"}.join("\n")
    }],
    [:stylesheets, %w(css less scss sass), lambda {|files|
      "/*\n" + files.map {|f| " *= require #{f}"}.join("\n") + "\n */"
    }],
    [:images, %w(png gif jpg jpeg), nil] # no manifest
  ]

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
      log.info "Gem #{component.gem_name}-#{component.version} already built"
      nil
    else
      validate_main

      main_files = EXTENSIONS.map do |name, exts, manifest|
        fs = info[:main].select do |e|
          ext_matches?(exts, e)
        end

        [name, fs, exts, manifest]
      end

      raise BuildError.new("Empty main") if main_files.all? {|_, fs, _, _| fs.empty? }

      basedir = File.dirname(main_files.map {|name, fs, _, _| fs }.flatten.first)

      main_files.map! do |name, fs, exts, manifest|
        puts "fs: #{fs.inspect}"
        if fs.empty?
          fs += find_files(basedir, exts)
        end
        [name, fs, exts, manifest]
      end

      main_files.map! do |name, fs, exts, manifest|
        fs.reject! do |f|
          exts.any? do |ext|
            f.match(/min\.#{ext}$/) && fs.include?(f.sub("min.", ""))
          end
        end

        [name, fs, exts, manifest]
      end

      main_files.each do |name, fs, exts, manifest|
        FileUtils.mkdir_p File.join(gem_root, "vendor", "assets", name.to_s)

        paths = fs.map do |f|
          path = File.join(component.name.to_s, f.sub(/^#{Regexp.escape(basedir)}/, ""))
          source = File.join(bower_root, f)
          target = File.join(gem_root, "vendor", "assets", name.to_s, path)
          log.info "Copying #{source} to #{target}"
          FileUtils.mkdir_p(File.dirname(target))
          FileUtils.cp source, target
          gem_files << File.join("vendor", "assets", name.to_s, path)
          path
        end

        # Manifest file
        if manifest && !fs.empty?
          manifest_filename = "#{component.name}.#{exts.first}"
          manifest_file = File.join(gem_root, "vendor", "assets", name.to_s, manifest_filename)
          log.info "Creating manifest file #{manifest_file}"
          File.open(manifest_file, "w") do |m|
            m.puts manifest.call(paths)
          end
          gem_files << File.join("vendor", "assets", name.to_s, manifest_filename)
        end
      end

      generate_gem_structure
      build_gem

      component.tmpfile = gem_pkg
      component
    end
  end

  def find_files(basedir, exts)
    dir = File.join(bower_root, basedir)
    log.info "Looking for #{exts} in #{dir}"
    Dir["#{dir}/**/*"].select do |f|
      ext_matches?(exts, f)
    end.map do |f|
      File.join(basedir, f.sub(dir, ""))
    end
  end

  def ext_matches?(exts, filename)
    ext = File.extname(filename)
    ext == "" ? false : exts.include?(ext.sub(".", ""))
  end

  def index
    @index ||= Index.new
  end

  def update_component_info
    component.version = info[:version].to_s.strip
    raise BuildError.new("Version is empty") if component.version == ""
  end

  def validate_main
    if !info[:main] || info[:main].empty?
      log.debug info.inspect
      raise BuildError.new("Missing main file")
    end
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
      ["#{GEM_PREFIX}#{dep}", fix_version_string(version)]
    end
  end

  def fix_version_string(version)
    if version =~ />=(.+)<(.+)/
      version = ">= #{$1}"
    end

    if version.strip == "latest"
      return nil
    end

    version.gsub!(/~(\d)/, '~> \1')
  end

  def gem_homepage
    if repo = info[:repository]
      if url = repo["url"]
        case url
        when %r|//github.com/(.+)/(.+)(.git)?|
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

  def build_gem
    sh gem_root, RAKE_BIN, "build"
  end
end
