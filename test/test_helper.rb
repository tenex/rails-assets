require "rubygems"
gem "bundler"
require "bundler/setup"
require 'minitest/autorun'
require "geminabox"
require "geminabox_test_case"

module TestMethodMagic
  def test(test_name, &block)
    define_method "test: #{test_name} ", &block
  end
end

MiniTest::Unit::TestCase.extend TestMethodMagic
