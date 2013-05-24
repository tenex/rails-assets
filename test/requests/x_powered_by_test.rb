require 'test_helper'
require 'minitest/unit'
require 'rack/test'

class XPoweredByTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Geminabox
  end

  %w[ / /gems ].each do |path|
    test "adds X-Powered-By when requesting '#{path}'" do
      get path
      assert_equal "geminabox #{GeminaboxVersion}", last_response.headers['X-Powered-By']
    end
  end
end
