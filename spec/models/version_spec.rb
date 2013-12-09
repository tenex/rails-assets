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
