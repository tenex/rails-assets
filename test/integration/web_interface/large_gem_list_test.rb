require 'test_helper'
require 'minitest/unit'
require 'rack/test'

class LargeGemListSpec < Geminabox::TestCase
  include Capybara::DSL

  test "more than 5 versions of the same gem" do
    Capybara.app = Geminabox::TestCase.app
    cache_fixture_data_dir('large_gem_list_test') do
      assert_can_push(:unrelated_gem, :version => '1.0')

      assert_can_push(:my_gem, :version => '1.0')
      assert_can_push(:my_gem, :version => '2.0')
      assert_can_push(:my_gem, :version => '3.0')
      assert_can_push(:my_gem, :version => '4.0')
      assert_can_push(:my_gem, :version => '5.0')
      assert_can_push(:my_gem, :version => '6.0')
    end

    visit url_for("/")

    assert_equal gems_on_page, %w[
      my_gem-6.0
      my_gem-5.0
      my_gem-4.0
      my_gem-3.0
      my_gem-2.0
      unrelated_gem-1.0
    ]

    page.click_link 'Older versions...'

    assert_equal gems_on_page, %w[
      my_gem-6.0
      my_gem-5.0
      my_gem-4.0
      my_gem-3.0
      my_gem-2.0
      my_gem-1.0
    ]
  end

  def gems_on_page
    page.all('a.download').
         map{|el| el['href'] }.
         map{|url| url.split("/").last.gsub(/\.gem$/, '') }
  end
end
