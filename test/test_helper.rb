$:.unshift File.expand_path("../../lib", __FILE__)
require "rubygems"

ARGV << "-v" unless ARGV.include?("-v")

require 'minitest'
require 'minitest/spec'
require 'minitest/pride'

require 'rails-assets'

class Minitest::Test
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
end

