require 'minitest/pride'
require 'rails/assets/utils'

module Rails::Assets
  describe Utils do
    describe '#remove_min_js_duplicates' do
      it 'removes min.js duplicates with the same prefix' do
        input = ['foo.js', 'foo.min.js', 'bar.min.js', 'bar.js']
        output = ['foo.js', 'bar.js']
        Utils.remove_min_js_duplicates(input).must_equal(output)
      end

      it 'does not remove minified files without non-minified ones' do
        input = ['foo.min.js', 'bar.min.js', 'bar.js']
        output = ['foo.min.js', 'bar.js']
        Utils.remove_min_js_duplicates(input).must_equal(output)
      end
    end

    describe '#select_javascripts' do
      it 'selects only javascript files' do
        input = ['foo.min.js', 'bar.js', 'bar.css', 'fiz']
        output = ['foo.min.js', 'bar.js']
        Utils.select_javascripts(input).must_equal(output)
      end

      it 'handles non-array input well' do
        input = 'foo.css'
        output = []
        Utils.select_javascripts(input).must_equal(output)
      end

      it 'should process output through remove_min_js_duplicates' do
        Utils.stub(:remove_min_js_duplicates, :ok) do
          Utils.select_javascripts("foo.js").must_equal(:ok)
        end
      end
    end
  end
end
