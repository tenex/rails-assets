require 'test_helper'

GeminaboxTestConfig.define "With path" do |config|
  config.url = "http://localhost/foo"

  app do
    map "/foo" do
      run Geminabox
    end
  end

  should_push_gem
end
