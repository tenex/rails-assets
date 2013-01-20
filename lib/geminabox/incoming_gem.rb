class Geminabox::IncomingGem
  attr_reader :spec, :gem_data

  def initialize(gem_data)
    @gem_data = gem_data
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
    File.join(Geminabox.settings.data, "gems", name)
  end

  def hexdigest
    Digest::SHA1.hexdigest(gem_data)
  end
end
