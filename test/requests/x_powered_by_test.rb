require 'test_helper'
require 'minitest/unit'
require 'rack/test'

class XPoweredByTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    Geminabox
  end

  %w[ / /gems ].each do |path|
    define_method "test: adds X-Powered-By when requesting '#{path}'" do
      get path
      assert_equal "geminabox #{Geminabox::VERSION}", last_response.headers['X-Powered-By']
    end
  end
end
