require "rubygems/package"

class Rails::Assets::IncomingGem
  def initialize(gem_data)
    # unless gem_data.respond_to? :read
    #   raise ArgumentError, "Expected an instance of IO"
    # end



    # if RbConfig::CONFIG["MAJOR"].to_i <= 1 and RbConfig::CONFIG["MINOR"].to_i <= 8
    #   @tempfile = Tempfile.new("gem")
    # else
    digest = Digest::SHA1.new
    @tempfile = Tempfile.new("gem", :encoding => 'binary')
    # end

    while data = gem_data.read(1024**2)
      @tempfile.write data
      digest << data
    end

    @tempfile.close
    @sha1 = digest.hexdigest

    # @root_path = root_path
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
    @spec ||= extract_spec
  end

  def extract_spec
    if Gem::Package.respond_to? :open
      Gem::Package.open(gem_data, "r", nil) do |pkg|
        return pkg.metadata
      end
    else
      Gem::Package.new(@tempfile.path).spec
    end
  end

  def name
    spec.name
  end

  def version
    spec.version
  end

  def filenname
    @name ||= begin
      filename = [spec.name, spec.version]
      filename.push(spec.platform) if spec.platform && spec.platform != "ruby"
      filename.join("-") + ".gem"
    end
  end

  def dest_filename
    File.join(@root_path, "gems", filenname)
  end

  def hexdigest
    @sha1
  end
end
