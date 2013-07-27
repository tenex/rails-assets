require 'minitest/pride'
require 'rails-assets/utils'

module RailsAssets
  describe Utils do
    class UtilsClass; include Utils; end

    describe '#remove_min_js_duplicates' do
      after do
        utils = UtilsClass.new
        utils.remove_min_js_duplicates(@input).must_equal(@output)
      end

      it 'removes min.js duplicates with the same prefix' do
        @input = ['foo.js', 'foo.min.js', 'bar.min.js', 'bar.js']
        @output = ['foo.js', 'bar.js']
      end

      it 'does not remove minified files without non-minified ones' do
        @input = ['foo.min.js', 'bar.min.js', 'bar.js']
        @output = ['foo.min.js', 'bar.js']
      end
    end

    describe '#select_javascripts' do
      after do
        utils = UtilsClass.new
        utils.select_javascripts(@input).must_equal(@output)
      end

      it 'selects only javascript files' do
        @input = ['foo.min.js', 'bar.js', 'bar.css', 'fiz']
        @output = ['foo.min.js', 'bar.js']
      end

      it 'handles non-array input well' do
        @input = 'foo.css'
        @output = []
      end

      it 'should process output through remove_min_js_duplicates' do
        @input = ['foo.js', 'foo.min.js']
        @output = ['foo.js']
      end
    end
  end
end
