module Build

  class Paths < Array

    def initialize(paths = nil)
      super((paths || []).flat_map do |path|
        path ? [Path.new(path).cleanpath] : []
      end.uniq)
    end

    def self.from(directory)
      new(Dir[File.join(directory, '**', '*')]).select(:file?)
    end

    def select(*args, &block)
      brock = proc { |e| e.send(*args) }
      args.size > 0 ? Paths.new(super(&brock)) : super(&block)
    end

    def select!(*args, &block)
      brock = proc { |e| e.send(*args) }
      args.size > 0 ? Paths.new(super(&brock)) : super(&block)
    end

    def reject(*args, &block)
      brock = proc { |e| e.send(*args) }
      args.size > 0 ? Paths.new(super(&brock)) : super(&block)
    end

    def map(*args, &block)
      brock = proc { |e| e.send(*args) }
      args.size > 0 ? Paths.new(super(&brock)) : super(&block)
    end

    def +(other)
      Paths.new(super(other))
    end

    def common_prefix
      return nil if self.size == 0

      splitted_files = self.map { |f| f.to_s.split('/') }
      min_size = splitted_files.map { |e| e.size }.min

      path = splitted_files.
        map { |dirs| dirs.take(min_size) }.
        transpose.
        take_while { |dirs| dirs.uniq.size == 1 }.
        map(&:first).join('/')

      Path.new(path).extname.present? ?
        Path.new(File.dirname(path)) : Path.new(path)
    end

    def find_main_asset(type, gem_name)
      Path.extension_classes[type].map do |ext|
        self.find do |path|
          path.extension?([ext]) && path.basename.to_s.split('.').first == gem_name
        end
      end.compact.first
    end
  end

  class Path < Pathname

    # Extensioins are sorted by priority
    def self.extension_classes
      {
        javascripts: ['coffee', 'js'],
        stylesheets: ['sass', 'scss', 'less', 'css'],
        images: ['png', 'jpg', 'jpeg', 'gif']
      }
    end

    def initialize(path = nil)
      super(path || '.')
    end

    def minified?
      to_s.include?('.min.')
    end

    def member_of?(klass)
      extension?(Path.extension_classes.fetch(klass, []))
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

  end

end
