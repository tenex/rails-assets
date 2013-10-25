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

    def component_transformations(bower_component, bower_path)
      bower_path = Path.new(bower_path)

      # Pass only relative, existent paths to transformator
      compute_transformations(
        bower_component.name,
        Paths.from(bower_path).map(:relative_path_from, bower_path),
        Paths.new(bower_component.main).
          map(:expand_path, bower_path).select(:exist?).
          map(:relative_path_from, bower_path)
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
      all_source_paths = all_source_paths.reject(:minified?)

      transformations = [:javascripts, :stylesheets, :images].flat_map do |type|
        main_paths = all_main_paths.select(:member_of?, type)

        target_dir = Path.new.join('vendor', 'assets', type.to_s)

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
                target_dir.join("#{gem_name}.#{generator[:extension]}")
              ]
            end
          end

        transforms = (source_paths.zip(target_paths) + [manifest_transform]).compact

        transforms = transforms.map do |source, target|
          if target.member_of?(:stylesheets) && target.extname == '.css'
            [source, Path.new(target.to_s.sub(/\.css$/, '.scss'))]
          else
            [source, target]
          end
        end

        transforms_hash = Hash[transforms]

        main_transforms = main_paths.map do |path|
          [path, transforms_hash[path]]
        end

        {
          all: transforms,
          main: main_transforms
        }
      end

      {
        all: Hash[transformations.flat_map { |t| t[:all] }],
        main: Hash[transformations.flat_map { |t| t[:main] }]
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

      transformations.values
    end

    def transform_relative_path(relative_path, source_path, transformations)
      mapping = Hash[transformations]
      new_img = mapping[source_path.append_relative_path(relative_path)]
      Path.new(new_img.to_s.sub(/.*?vendor\/assets\/images\//, ""))
    end

    def process_asset(file_name, source, transformations)
      return source if file_name.nil?

      if file_name.member_of?(:stylesheets)
        extensions = Path.extension_classes[:images]
        source.gsub /url\(["'\s]?([^\)]+\.(#{extensions.join('|')}))["'\s]?\)/i do |match|
          "image-url(\"#{transform_relative_path($1, file_name, transformations)}\")"
        end
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
              "//= require #{shorten_filename(filename, Path.extension_classes[:javascripts])}"
            end.join("\n")
          }
        },
        stylesheets: {
          extension: 'css',
          processor: lambda { |files|
            "/*\n" +
            files.map { |filename|
              " *= require #{shorten_filename(filename, Path.extension_classes[:stylesheets])}"
            }.join("\n") +
            "\n */"
          }
        }
      }
    end

    def shorten_filename(filename, extensions)
      filename.to_s.split('.').reverse.
        drop_while { |e| extensions.include?(e.downcase) }.
        reverse.join('.')
    end
  end
end
