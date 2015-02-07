module Build

  class Path < Pathname

    # Extensions are sorted by priority
    def self.extension_classes
      {
        javascripts: ['coffee', 'js'],
        stylesheets: ['sass', 'scss', 'less', 'css', 'styl'],
        images: ['png', 'jpg', 'jpeg', 'gif', 'cur', 'ico'],
        fonts: ['woff', 'woff2', 'ttf', 'otf', 'eot', 'svg'],
        flash: ['swf'],
        templates: ['html'],
        documents: ['json']
      }
    end

    def self.allowed_main_extensions
      {
        javascripts: ['coffee', 'js'],
        stylesheets: ['sass', 'scss', 'css'],
        images: ['png', 'jpg', 'jpeg', 'gif', 'cur', 'ico'],
        fonts: ['woff', 'woff2', 'ttf', 'otf', 'eot', 'svg'],
        flash: ['swf'],
        templates: ['html'],
        documents: ['json']
      }
    end

    def initialize(path = nil)
      super(path ? Pathname.new(path).cleanpath : Pathname.new('.').cleanpath)
    end

    def minified?
      to_s.include?('.min.')
    end

    def member_of?(klass)
      extension?(Path.extension_classes.fetch(klass, []))
    end

    def main_of?(klass)
      extension?(Path.allowed_main_extensions.fetch(klass, []))
    end

    def descendant?(directory)
      !relative_path_from(Path.new(directory)).to_s.split('/').include?('..')
    end

    def prefix(path)
      Path.new(path).join(self)
    end

    def join(*elements)
      Path.new(super(*elements))
    end

    def extension?(extensions)
      extensions.any? do |extension|
        !!to_s.match(/\.#{extension}(?:[\W]|$)/)
      end
    end

    def append_relative_path(exp)
      Path.new(File.expand_path("../#{exp}", "/#{self.to_s}")[1..-1])
    end

    def in_directory?(dirnames)
      [*dirnames].any? do |dirname|
        self.each_filename.to_a.include?(dirname)
      end
    end
  end

end
