# == Schema Information
#
# Table name: versions
#
#  id            :integer          not null, primary key
#  component_id  :integer
#  string        :string(255)
#  dependencies  :hstore
#  created_at    :datetime
#  updated_at    :datetime
#  build_status  :string(255)
#  build_message :text
#  asset_paths   :text             default([]), is an Array
#  main_paths    :text             default([]), is an Array
#  rebuild       :boolean          default(FALSE)
#  bower_version :string(255)
#  position      :string(1023)
#  prerelease    :boolean          default(FALSE)
#

require 'spec_helper'

describe Version do
  context '#gem_path' do
    it 'returns absolute path to gem on disk' do
      component = Component.new(name: 'jquery')
      version = Version.new(string: '1.0.2')
      version.component = component

      expect(version.gem_path.to_s).
        to include('public/gems/rails-assets-jquery-1.0.2.gem')
    end
  end
end
