module Build
  class BuildError < Exception
    attr_reader :opts
    def initialize(message, opts = {})
      super(message)
      @opts = opts
    end
  end
end
