class FailedJob < ActiveRecord::Base
  serialize :args, Array

  def retry!
    klass.constantize.perform_async(args)
  end
end
