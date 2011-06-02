class Geminabox::GemVersionCollection
  include Enumerable

  def initialize(initial_gems = [])
    @gems = Hash.new{|h,k| h[k] = [] }
    initial_gems.each{|g| self << g }
  end

  def <<(gemdef)
    name,version,_ = gemdef
    return self if name.nil?
    @gems[name] += [version].flatten
    @gems[name].sort!
    self
  end

  def + other
    other.inject(self.class.new(self)){|new_set, gemdef|
      new_set << gemdef
    }
  end

  def each(&block)
    @gems.sort_by{|name, versions| name }.each(&block)
  end
end
