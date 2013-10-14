require 'spec_helper'

module Build
  describe Transformer do
    context '#compute_transformations' do
      def targets(asset_paths, main_paths = [])
        Paths.new(Transformer.compute_transformations(
          'foobar',
          Paths.new(asset_paths),
          Paths.new(main_paths)
        ).map(&:last))
      end

      def mappings(asset_paths, main_paths = [])
        Hash[Transformer.compute_transformations(
          'foobar',
          Paths.new(asset_paths),
          Paths.new(main_paths)
        ).map { |source, target| [target.to_s, source] } ]
      end

      it 'puts javascript files to javascripts directory' do
        expect(
          targets(['foo.js'])
        ).to eq(Paths.new(['vendor/assets/javascripts/foobar/foo.js']))
      end

      it 'puts stylesheet files to stylesheets directory' do
        expect(
          targets(['foo.css'])
        ).to eq(Paths.new(['vendor/assets/stylesheets/foobar/foo.scss']))
      end

      it 'puts image files to images directory' do
        expect(
          targets(['foo.png'])
        ).to eq(Paths.new(['vendor/assets/images/foobar/foo.png']))
      end

      it 'ignores minified files' do
        expect(
          targets(['foo.min.js', 'foo.js'])
        ).to eq(Paths.new(['vendor/assets/javascripts/foobar/foo.js']))
      end

      it 'generates manifest for javascript files' do
        expect(
          targets(['foo.js'], ['foo.js'])
        ).to eq(Paths.new([
          'vendor/assets/javascripts/foobar/foo.js',
          'vendor/assets/javascripts/foobar.js'
        ]))
      end

      it 'generates proper javascript manifest' do
        expect(
          mappings(
            ['foo.js'], ['foo.js']
          )['vendor/assets/javascripts/foobar.js']
        ).to include('require foobar/foo')
      end

      it 'does not include extensions in required files' do
        expect(
          mappings(
            ['foo.js'], ['foo.js']
          )['vendor/assets/javascripts/foobar.js']
        ).to_not include('require foobar/foo.js')
      end

      it 'generates manifest for stylesheet files' do
        expect(
          targets(['foo.css'], ['foo.css'])
        ).to eq(Paths.new([
          'vendor/assets/stylesheets/foobar/foo.scss',
          'vendor/assets/stylesheets/foobar.scss'
        ]))
      end

      it 'generates proper stylesheet manifest' do
        expect(
          mappings(
            ['foo.css'], ['foo.css']
          )['vendor/assets/stylesheets/foobar.scss']
        ).to include('require foobar/foo')
      end

      it 'does not include extensions in required files' do
        expect(
          mappings(
            ['foo.css'], ['foo.css']
          )['vendor/assets/stylesheets/foobar.scss']
        ).to_not include('require foobar/foo.scss')
      end

      it 'flattens paths for if main javascript is set' do
        expect(
          targets(['dist/foo.js'], ['dist/foo.js'])
        ).to eq(Paths.new([
          'vendor/assets/javascripts/foobar/foo.js',
          'vendor/assets/javascripts/foobar.js'
        ]))
      end

      it 'flattens paths for if main stylesheet is set' do
        expect(
          targets(['dist/css/foo.css'], ['dist/css/foo.scss'])
        ).to eq(Paths.new([
          'vendor/assets/stylesheets/foobar/foo.scss',
          'vendor/assets/stylesheets/foobar.scss'
        ]))
      end

      it 'transforms all css files to scss ones to support asset urls' do
        expect(
          targets(['foo.css'])
        ).to eq(Paths.new([
          'vendor/assets/stylesheets/foobar/foo.scss'
        ]))
      end
    end

    context '#process_transformations!' do
      it 'transforms urls in css files' do
        source_file = Path.new('style.css')
        target_file = Path.new('style.scss')

        File.write('/tmp/style.css', "body {\n  background-image: url(foo/bar.png)\n}")

        Transformer.process_transformations!([[source_file, target_file]], '/tmp', '/tmp')
        expect(File.read('/tmp/style.scss')).to include('image-url("foo/bar.png")')
      end
    end
  end
end
