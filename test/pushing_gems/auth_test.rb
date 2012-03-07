require 'test_helper'

GeminaboxTestConfig.define "With Rack::Auth::Basic" do |config|

  config.url = "http://foo:bar@localhost/"

  app do
    use Rack::Auth::Basic do |username, password|
      username == "foo" and password == "bar"
    end

    run Geminabox
  end

  should_push_gem

end
