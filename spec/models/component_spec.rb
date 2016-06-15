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

require 'spec_helper'

describe Component do
  subject { create :component }

  it 'should have a summary_cache present upon creation' do
    expect(subject.summary_cache).to be_present
  end

  it 'should see that a new version has appeared' do
    initial_versions = subject.summary_cache['versions'].clone
    create :version, component: subject
    expect(subject.versions.length).to be > initial_versions.length
  end

  it 'should be able to be deleted without exploding' do
    create_list :version, 5, component: subject # for callbacks
    subject.destroy!
    expect(subject).to be_destroyed
  end
end
