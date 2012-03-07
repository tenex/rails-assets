require 'test_helper'

GeminaboxTestConfig.define "With bad data dir" do |config|
  config.data = "/dev/null"

  test "report the error back to the user" do
    assert_match %r{Please ensure /dev/null is a directory.}, geminabox_push(gem_file(:example))
  end
end

GeminaboxTestConfig.define "With an unwritable data dir" do |config|
  config.data = "/"

  test "report the error back to the user" do
    assert_match %r{Please ensure / is writable by the geminabox web server.}, geminabox_push(gem_file(:example))
  end
end

GeminaboxTestConfig.define "With an unwritable, none-existent data dir" do |config|
  config.data = "/geminabox-fail"

  test "report the error back to the user" do
    assert_match %r{Could not create /geminabox-fail}, geminabox_push(gem_file(:example))
  end
end

GeminaboxTestConfig.define "With a writable, none-existent data dir" do |config|
  config.data += "/more/layers/of/dirs"

  test "create the data dir" do
    FileUtils.rm_rf(config.data)
    assert_can_push
  end
end
