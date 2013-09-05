module Build
  class Extension
    attr_accessor :assets_dir, :exts, :manifest_proc, :files

    def initialize(assets_dir, exts, &block)
      @assets_dir, @exts = assets_dir, exts
      @manifest_proc = block
    end

    def matches?(filename)
      ext = File.extname(filename)
      !ext.blank? && exts.include?(ext.sub(".", ""))
    end
  end
end
