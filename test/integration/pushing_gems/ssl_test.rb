require 'test_helper'

class SSLTest < Geminabox::TestCase
  url "https://127.0.0.1/"
  ssl true
  should_push_gem
  # test "s" do
  #   puts url_for("/")
  #   sleep 1000
  # end
end
