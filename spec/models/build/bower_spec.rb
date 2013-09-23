require 'spec_helper'

describe Build::Bower do
  context '#info' do
    it 'returns hash of component info' do
      info = Build::Bower.info('angular')
      expect(info).to be_kind_of(Hash)
      expect(info['versions']).to be_kind_of(Array)
    end
  end
end
