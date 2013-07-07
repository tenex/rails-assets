class Rails::Assets::GemVersion
  attr_accessor :name, :number, :platform

  def initialize(name, number, platform)
    @name = name
    @number = number
    @platform = platform
  end

  def ruby?
    !!(platform =~ /ruby/i)
  end

  def version
    Gem::Version.create(number)
  end

  def <=>(other)
    sort = other.name <=> name
    sort = version <=>  other.version       if sort.zero?
    sort = (other.ruby? && !ruby?) ? 1 : -1 if sort.zero? && ruby? != other.ruby?
    sort = other.platform <=> platform      if sort.zero?

    sort
  end

  def ==(other)
    return false unless other.class == self.class
    [name, number, platform] == [other.name, other.number, other.platform]
  end

  def gemfile_name
    included_platform = ruby? ? nil : platform
    [name, number, included_platform].compact.join('-')
  end
end
