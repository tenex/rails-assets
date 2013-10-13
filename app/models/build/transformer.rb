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

      [:javascripts, :stylesheets, :images].flat_map do |type|
        main_paths = all_main_paths.select(:member_of?, type)

        source_dir = main_paths.common_prefix || Path.new
        target_dir = Path.new.join('vendor', 'assets', type.to_s)

        source_paths = all_source_paths.select(:member_of?, type).
          select(:descendant?, source_dir) + main_paths

        relative_paths = source_paths.map(:relative_path_from, source_dir)
        target_paths = relative_paths.map(:prefix, target_dir.join(gem_name))

        manifest_transform =
          if generator = manifest_generators[type]
            manifest_paths = main_paths.map(:relative_path_from, source_dir)
            unless manifest_paths.empty?
              [
                generator[:processor].call(manifest_paths),
                target_dir.join("#{gem_name}.#{generator[:extension]}")
              ]
            end
          end

        (source_paths.zip(target_paths) + [manifest_transform]).compact
      end
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
          source = bower_path.join(source)
          Rails.logger.info "Copying #{source} to #{target}"
          FileUtils.cp(source, target)
        else
          File.open(target, "w") do |file|
            file.write(source)
          end
        end
      end

      transformations.map(&:last)
    end

    private

    def manifest_generators
      @manifest_generators ||= {
        javascripts: {
          extension: 'js',
          processor: lambda { |files|
            files.map do |file_name|
              "//= require #{file_name}"
            end.join("\n")
          }
        },
        stylesheets: {
          extension: 'css',
          processor: lambda { |files|
            "/*\n" +
            files.map { |file_name|
              " *= require #{file_name}"
            }.join("\n") +
            "\n */"
          }
        }
      }
    end
  end
end
