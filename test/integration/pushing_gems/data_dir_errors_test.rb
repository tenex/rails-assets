require 'test_helper'

class InvalidDataDirTest < Geminabox::TestCase
  data "/dev/null"

  test "report the error back to the user" do
    assert_match %r{Please ensure /dev/null is a directory.}, geminabox_push(gem_file(:example))
  end
end

class UnwritableDataDirTest < Geminabox::TestCase
  def setup
    super

    FileUtils.mkdir '/tmp/read_only'
    FileUtils.chmod 0444, '/tmp/read_only'
  end

  def teardown
    super

    FileUtils.rmdir '/tmp/read_only'
  end

  data "/tmp/read_only"

  test "report the error back to the user" do
    assert_match %r{Please ensure /tmp/read_only is writable by the geminabox web server.}, geminabox_push(gem_file(:example))
  end
end

class UnwritableUncreatableDataDirTest < Geminabox::TestCase
  data "/geminabox-fail"

  test "report the error back to the user" do
    assert_match %r{Could not create /geminabox-fail}, geminabox_push(gem_file(:example))
  end
end

class WritableNoneExistentDataDirTest < Geminabox::TestCase
  data "#{data}/more/layers/of/dirs"

  test "create the data dir" do
    FileUtils.rm_rf(config.data)
    assert_can_push
  end
end
