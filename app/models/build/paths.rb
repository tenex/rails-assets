module Build

  class Paths < Array

    def initialize(paths = nil)
      super((paths || []).map do |path|
        Path.new(path).cleanpath
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

      File.file?(path) ?
        Path.new(File.dirname(path)) : Path.new(path)
    end
  end

  class Path < Pathname

    def minified?
      to_s.include?('.min.')
    end

    def javascript?
      extension? ['js', 'coffee']
    end

    def stylesheet?
      extension? ['css', 'less', 'scss', 'sass']
    end

    def image?
      extension? ['png', 'gif', 'jpg', 'jpeg']
    end

    def descendant?(directory)
      !relative_path_from(Path.new(directory)).to_s.split('/').include?('..')
    end

    private

    def extension?(extensions)
      extensions.any? do |extension|
        !!to_s.match(/\.#{extension}(?:[\W]|$)/)
      end
    end

  end

end
