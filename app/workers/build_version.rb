class BuildVersion
  include Sidekiq::Worker

  sidekiq_options queue: 'default', unique: :all, retry: 3

  sidekiq_retry_in do |count|
    (count**5) + 60 + (rand(30) * (count + 1))
  end

  sidekiq_retries_exhausted do |msg|
    FailedJob.find_or_create_by(name: msg['args'].join('#')) do |j|
      j.worker  = msg['class']
      j.args    = msg['args']
      j.message = msg['error_message']
    end
  end

  def perform(bower_name, version)
    return if FailedJob.exists?(name: "#{bower_name}##{version}")

    Build::Converter.run!(bower_name, version)
  end
end
