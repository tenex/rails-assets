module Build
  class BowerError < BuildError
    attr_reader :path, :command, :details

    def initialize(message, details, path = nil, command = nil)
      @details, @path, @command = details, path, command
      super(message)
    end

    def self.from_shell_error(e)
      parsed_json = JSON.parse(e.message)
      error = parsed_json.find{ |h| h['level'] == 'error' }
      BowerError.new(error['message'], error['details'], e.path, e.command)
    end
  end
end
