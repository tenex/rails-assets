class Geminabox::IncomingGem
  attr_reader :spec, :gem_data

  def initialize(gem_data, root_path = Geminabox.settings.data)
    @gem_data = gem_data
    @root_path = root_path
  end

  def valid?
    spec && spec.name && spec.version
  rescue Gem::Package::Error
    false
  end

  def spec
    return @spec if @spec
    Gem::Package.open(StringIO.new(gem_data), "r", nil) do |pkg|
      @spec = pkg.metadata
    end
  end

  def name
    "#{spec.name}-#{spec.version}.gem"
  end

  def dest_filename
    File.join(@root_path, "gems", name)
  end

  def hexdigest
    Digest::SHA1.hexdigest(gem_data)
  end
end
