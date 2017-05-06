# This logger forces the logs to JSON format
class ActiveSupport::Logger::SimpleFormatter
  def call(severity, _time, _progname, msg)
    msgObj = {}
    begin
      msgObj = JSON.parse(msg)
    rescue JSON::ParserError => e
      msgObj[:data] = msg
    end
    msgObj[:severity] = severity

    # This can use JSON.pretty_generate(msgObj) to make it human friendly
    if Rails.env.development?
      "[#{severity}] #{msg.strip}\n"
    else
      "#{msgObj.to_json}\n"
    end
  end
end
