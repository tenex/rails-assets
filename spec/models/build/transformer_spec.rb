require 'spec_helper'

module Build
  describe Transformer do
    context '#compute_transformations' do
      def targets(asset_paths, main_paths = [])
        Paths.new(Transformer.compute_transformations(
          'foobar',
          Paths.new(asset_paths),
          Paths.new(main_paths)
        )[:all].values)
      end

      def mappings(asset_paths, main_paths = [])
        Hash[Transformer.compute_transformations(
          'foobar',
          Paths.new(asset_paths),
          Paths.new(main_paths)
        )[:all].invert.map { |s, t| [s.to_s, t.to_s] }]
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

        transformations = Hash[[
          [source_file, target_file],
          [Path.new('foo/bar.png'), Path.new('vendor/assets/images/foo.png')]
        ]]

        File.write('/tmp/style.css', "body {\n  background-image: url(foo/bar.png)\n}")
        FileUtils.mkdir_p('/tmp/foo')
        File.write('/tmp/foo/bar.png', "BINARY")

        Transformer.process_transformations!(transformations, '/tmp', '/tmp')
        expect(File.read('/tmp/style.scss')).to include('image-url("foo.png")')
      end
    end

    context '#transform_relative_path' do
      it 'properly transforms relative path' do
        expect(Transformer.transform_relative_path(
          Path.new('../images/image.png'), Path.new('dist/css/foobar.css'),
          Hash[[
            [Path.new('./dist/css/foobar.css'), Path.new('css/foobar.css')],
            [Path.new('./dist/images/image.png'), Path.new('vendor/assets/images/fiz/img.png')],
            [Path.new('./dist/image.png'), Path.new('vendor/assets/images/fuz/img.png')]
          ]]
        )).to eq(Path.new('fiz/img.png'))
      end
    end

    context '#shorten_filename' do
      it 'leaves custom extensions' do
        filename = Transformer.shorten_filename(
          'jquery.cookie.css', Path.extension_classes[:stylesheets]
        )

        expect(filename).to eq('jquery.cookie')
      end
      
      it 'removes all non-custom extension' do
        filename = Transformer.shorten_filename(
          'jquery.js.cookie.css.scss', Path.extension_classes[:stylesheets]
        )

        expect(filename).to eq('jquery.js.cookie')
      end

      it 'also deals with paths' do
        filename = Transformer.shorten_filename(
          '/foo/bar/jquery.cookie.sass', Path.extension_classes[:stylesheets]
        )

        expect(filename).to eq('/foo/bar/jquery.cookie')
      end

      it 'deals with Path object' do
        filename = Transformer.shorten_filename(
          Path.new('/jquery.cookie.sass'), Path.extension_classes[:stylesheets]
        )

        expect(filename).to eq('/jquery.cookie')
      end
    end
  end
end
