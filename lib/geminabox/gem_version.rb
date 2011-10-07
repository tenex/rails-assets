class Geminabox::GemVersion
  attr_accessor :name, :number, :platform
  
  def initialize(name, number, platform)
    @name = name
    @number = number
    @platform = platform
  end
  
  def gemfile_name
    included_platform = platform =~ /ruby/i ? nil : platform
    [name, number, included_platform].compact.join('-')
  end
end
