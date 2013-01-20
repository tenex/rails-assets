class Geminabox::IncomingGem
  def initialize(gem_data, root_path = Geminabox.settings.data)
    unless gem_data.respond_to? :read
      raise ArgumentError, "Expected an instance of IO"
    end

    digest = Digest::SHA1.new
    @tempfile = Tempfile.new("gem", :encoding => 'binary')
    while data = gem_data.read(1024**2)
      @tempfile.write data
      digest << data
    end
    @tempfile.close
    @sha1 = digest.hexdigest

    @root_path = root_path
  end

  def gem_data
    File.open(@tempfile.path, "rb")
  end

  def valid?
    spec && spec.name && spec.version
  rescue Gem::Package::Error
    false
  end

  def spec
    unless @spec
      Gem::Package.open(gem_data, "r", nil) do |pkg|
        @spec = pkg.metadata
      end
    end
    @spec
  end

  def name
    "#{spec.name}-#{spec.version}.gem"
  end

  def dest_filename
    File.join(@root_path, "gems", name)
  end

  def hexdigest
    @sha1
  end
end
