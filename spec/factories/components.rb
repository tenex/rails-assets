# == Schema Information
#
# Table name: components
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  description   :text
#  homepage      :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#  bower_name    :string(255)
#  summary_cache :json
#
# Indexes
#
#  index_components_on_name  (name) UNIQUE
#

FactoryGirl.define do
  factory :component do
    name { "#{Faker::Hipster.words(3).join('-')}.js" }
    description { Faker::Company.bs }
    homepage { Faker::Internet.url }
    bower_name { name }
  end
end
