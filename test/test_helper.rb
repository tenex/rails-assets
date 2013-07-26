require "rubygems"
require "bundler/setup"

require 'rails/assets'

require 'minitest/autorun'
require 'minitest/pride'

require 'fileutils'
require 'test_support/gem_factory'

module TestMethodMagic
  def test(test_name, &block)
    define_method "test_method: #{test_name} ", &block
  end
end

class Minitest::Test
  extend TestMethodMagic

  TEST_DATA_DIR="/tmp/rails-assets-test-data"

  def clean_data_dir
    FileUtils.rm_rf(TEST_DATA_DIR)
    FileUtils.mkdir(TEST_DATA_DIR)
    RailsAssets.data = TEST_DATA_DIR
  end

  def silence_stream(stream)
    old_stream = stream.dup
    stream.reopen('/dev/null')
    stream.sync = true
    yield
  ensure
    stream.reopen(old_stream)
  end

  def silence
    silence_stream(STDERR) do
      silence_stream(STDOUT) do
        yield
      end
    end
  end

  def inject_gems(&block)
    silence do
      yield GemFactory.new(File.join(RailsAssets.data, "gems"))
      Gem::Indexer.new(RailsAssets.data).generate_index
    end
  end

end

