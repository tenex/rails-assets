#     ____       ____       ____       ____       ____
#    ||o o|     ||o o|     ||o o|     ||o o|     ||o o|
#    ||===|  ___||===|  ___||===|  ___||===|  ___||===|  ____
#  .-.`---.-||o o|---.-||o o|---.-||o o|---.-||o o|---.-||o o|
#  | | o .o ||===|  ___||===|  ___||===|  ___||===|  ___||===|  ____
#  | | o:..-.`---.-||o o|---.-||o o|---.-||o o|---.-||o o|---.-||o o|
#  | |    | | o .o ||===|     ||===|     ||===|     ||===|     ||===|
#  `-".-.-| | o:..-.`---'-. .-.`---'-. .-.`---'-. .-.`---'-. .-.`---'-.
module Build
  module Transformer extend self

    def component_transformations(bower_component)
      compute_transformations(
        bower_component.name,
        bower_component.paths,
        bower_component.main_paths
      )
    end

    # Public: generates transformations mapping component files to gem files
    #
    # name - The String representing name of the component
    # all_source_paths - The Paths of all assets relative to component directory
    # all_main_paths - The Paths of main assets relative to component directory
    #
    # Returns file transformations to be made
    #   each transform is in form [source_path, target_path] or [source, target_path]
    def compute_transformations(gem_name, all_source_paths, all_main_paths = Paths.new)
      all_source_paths = Paths.new(all_source_paths.reject do |file|

        has_unminified = all_source_paths.
          include?(Path.new(file.to_s.sub('.min.', '.')))

        in_special_dir = file.in_directory?( %w(
          spec test perf minified docs examples min
          node_modules bower_components tests samples
        ))

        is_unsupported = file.to_s.
          match(/(gzip|map|nuspec|gz|jar|php|orig|pre|post|sh|cfg|md|txt|~|zip|bak|5|git-id|in|ls|map|min|new|old|rej|sample|example)$/)

        is_unsupported ||= %w(
          bower.json
          .bower.json
          component.json
          package.json
          composer.json
        ).include?(file.to_s.split('/').last)

        main_in_same_dir = all_main_paths.map(:dirname).any? do |dir|
          file.descendant?(dir)
        end

        (file.minified? && has_unminified) ||
        (in_special_dir && !main_in_same_dir) ||
        is_unsupported
      end.sort_by(&:to_s))

      transformations = Path.extension_classes.keys.flat_map do |type|
        main_paths = all_main_paths.select(:main_of?, type)

        target_dir = Path.new.join('app', 'assets', type.to_s)

        source_paths = all_source_paths.select(:member_of?, type)

        if main_paths.empty?
          # Possibly empty too, try to find asset with the same name as gem
          main_paths = Paths.new([source_paths.find_main_asset(type, gem_name)])
        end

        source_dir = main_paths.common_prefix || Path.new

        source_paths = (source_paths + main_paths).
          select(:descendant?, source_dir)

        relative_paths = source_paths.map(:relative_path_from, source_dir)
        target_paths = relative_paths.map(:prefix, target_dir.join(gem_name))

        manifest_transform =
          if generator = manifest_generators[type]
            manifest_paths = main_paths.map(:relative_path_from, source_dir).
              map(:prefix, gem_name)
            unless manifest_paths.empty?
              [
                generator[:processor].call(manifest_paths),

                target_dir.join(manifest_path(gem_name, generator))
              ]
            end
          end

        transforms = (source_paths.zip(target_paths) + [manifest_transform]).compact

        transforms = transforms.map do |source, target|
          if target.member_of?(:stylesheets) && target.extname == '.css'
            scss_path = Path.new(target.to_s.sub(/\.css$/, '.scss'))
            [source, scss_path]
          else
            [source, target]
          end
        end

        main_transforms = main_paths.map do |path|
          transforms.find { |source, _| source == path }
        end.compact

        {
          all: transforms,
          main: main_transforms
        }
      end

      {
        all: transformations.flat_map { |t| t[:all] },
        main: transformations.flat_map { |t| t[:main] }
      }
    end

    # Public: processes transfirmations by copying or generating gem files
    #
    # bower_dir - The Path where transformation sources can be found
    # gem_dir - The Path where transfirmation destinations can be found
    #
    # Returns list of saved files
    def process_transformations!(transformations, bower_path, gem_path)
      bower_path = Path.new(bower_path)
      gem_path = Path.new(gem_path)

      transformations.each do |source, target|
        target = gem_path.join(target)
        target.dirname.mkpath

        if source.is_a?(Pathname)
          file_name = source
          source = bower_path.join(source) unless source.absolute?
          source = File.read(source)
        else
          file_name = nil
        end

        File.open(target, "w") do |file|
          file.write(process_asset(file_name, source, transformations))
        end
      end

      transformations.map(&:last)
    end

    def exist_relative_path?(relative_path, source_path, transformations)
      transformations.any? { |s, _| s == source_path.append_relative_path(relative_path) }
    end

    def transform_relative_path(ext_class, relative_path, source_path, transformations)
      new_img = transformations.find { |s, _| s == source_path.append_relative_path(relative_path) }.last
      Path.new(new_img.to_s.sub(/.*?app\/assets\/#{ext_class}\//, ""))
    end

    def process_asset(file_name, source, transformations)
      return source if file_name.nil?

      if file_name.member_of?(:stylesheets)
        new_source = source.dup.
          encode("UTF-16be", invalid: :replace, replace: '', undef: :replace).
          encode('UTF-8')

        {images: :image, fonts: :font}.each do |ext_class, asset_type|
          extensions = Path.extension_classes.fetch(ext_class)
          new_source.gsub! /(?<!-)url\(\s*(["']*)([^\)]+\.(?:#{extensions.join('|')}))(\??#?[^\s"'\)]*)\1\s*\)/i do |match|

            if exist_relative_path?($2, file_name, transformations)
              "#{asset_type}-url(\"#{transform_relative_path(ext_class, $2, file_name, transformations)}#{$3}\")"
            else
              match.to_s
            end

          end
        end

        new_source.gsub!(/^[ \t]*?\/\*[#@]\s+sourceMappingURL=[^\*]+\*\/[\r\n|\n]?/i, '')

        new_source
      elsif file_name.member_of?(:javascripts)
        new_source = source.dup.
          encode("UTF-16be", invalid: :replace, replace: '', undef: :replace).
          encode('UTF-8')

        new_source.gsub!(/^[ \t]*?\/\/[#@]\s+sourceMappingURL=[^\r\n]+[\r\n|\n]?/i, '')

        new_source
      else
        source
      end
    end

    def manifest_generators
      @manifest_generators ||= {
        javascripts: {
          extension: 'js',
          processor: lambda { |files|
            files.map do |filename|
              "//= require #{transform_filename(filename)}\n"
            end.join("")
          }
        },
        stylesheets: {
          extension: 'scss',
          processor: lambda { |files|
            files.map { |filename|
              "@import '#{transform_filename(filename)}';\n"
            }.join("")
          }
        }
      }
    end

    def transform_filename(filename)
      filename.to_s.gsub(/\.css$/, '.scss')
    end

    def manifest_path(gem_name, generator)
      revised_gem_name = check_gem_name(gem_name)
      "#{revised_gem_name}.#{generator[:extension]}"
    end

    # Verify that the name does not include a dot so that
    # the resulting file doesn't get a wrong filename
    #
    # gem_name: A String containing the name of the gem we will create
    #
    # Returns String with the verified name
    def check_gem_name(gem_name)
      revised_gem_name = gem_name.split(/\./)
      revised_gem_name.first
    end
  end
end

