require 'test_helper'

GeminaboxTestConfig.define "With path" do |config|
  config.url = "http://localhost/foo"

  config.app do
    map "/foo" do
      run Geminabox
    end
  end

  config.should_push_gem
end
