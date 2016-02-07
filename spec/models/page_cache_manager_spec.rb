require 'spec_helper'

describe PageCacheManager do
  let(:example_path) { 'public/components.json' }
  before(:each) do
    described_class.stub(perform_caching: true)
  end

  after(:each) do
    File.delete(example_path) if File.exists?(example_path)
  end

  describe '#expire_page' do
    it 'removes cached assets' do
      `touch #{example_path}`
      File.should exist(example_path)

      PageCacheManager.new.expire_page(controller: :components, action: :index, format: :json)
      File.should_not exist(example_path)
    end
  end
end
