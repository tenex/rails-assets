# == Schema Information
#
# Table name: failed_jobs
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  worker     :string(255)
#  args       :text
#  message    :text
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_failed_jobs_on_name  (name)
#

class FailedJob < ActiveRecord::Base
  serialize :args, Array

  def retry!
    klass.constantize.perform_async(args)
  end
end
