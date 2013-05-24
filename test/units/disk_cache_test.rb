require 'test_helper'

class DiskCacheTest < Minitest::Test
  DIR = "/tmp/geminabox-disk-cache-test"
  def setup
    FileUtils.rm_rf(DIR)
  end

  def subject
    @subject ||= Geminabox::DiskCache.new(DIR)
  end

  def test_cache_some_stuff
    called = 0
    callable = lambda{
      subject.cache("foo") do
        called += 1
        "HELLO"
      end
    }
    assert_equal "HELLO", callable.call
    assert_equal "HELLO", callable.call
    assert_equal 1, called
  end

  def test_flushing_the_cache
    assert_equal "foo", subject.cache("foo"){ "foo" }
    assert_equal "foo", subject.cache("foo"){ "bar" }

    subject.flush

    assert_equal "bar", subject.cache("foo"){ "bar" }
  end

  def test_multiple_keys
    assert_equal "foo", subject.cache("foo"){ "foo" }
    assert_equal "bar", subject.cache("bar"){ "bar" }
  end

  def test_flushing_a_key
    assert_equal "foo", subject.cache("foo"){ "foo" }
    assert_equal "bar", subject.cache("bar"){ "bar" }

    subject.flush_key("foo")

    assert_equal "baz", subject.cache("foo"){ "baz" }
    assert_equal "bar", subject.cache("bar"){ "baz" }
  end

  def teardown
    FileUtils.rm_rf(DIR)
  end
end
