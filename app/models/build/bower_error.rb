module Build
  class BowerError < BuildError
    attr_reader :path, :command, :details, :code

    ENOTFOUND = 'ENOTFOUND'.freeze

    def initialize(message, details, path = nil, command = nil, code = nil)
      @details = details
      @path = path
      @command = command
      @code = code
      super(message)
    end

    def not_found?
      @code == ENOTFOUND
    end

    def self.from_shell_error(e)
      parsed_json = JSON.parse(e.message)
      error = parsed_json.find { |h| h['level'] == 'error' }
      BowerError.new(error['message'], error['details'],
                     e.path, e.command, error['code'])
    end
  end
end
