require 'spec_helper'

module Build
  describe Transformer do
    context '#compute_transformations' do
      def targets(asset_paths, main_paths = [])
        Paths.new(Transformer.compute_transformations(
          'foobar',
          Paths.new(asset_paths),
          Paths.new(main_paths)
        )[:all].map(&:last))
      end

      def mappings(asset_paths, main_paths = [])
        Hash[Transformer.compute_transformations(
          'foobar',
          Paths.new(asset_paths),
          Paths.new(main_paths)
        )[:all].map { |s, t| [t.to_s, s.to_s] }]
      end

      it 'puts javascript files to javascripts directory' do
        expect(
          targets(['foo.js'])
        ).to eq(Paths.new(['app/assets/javascripts/foobar/foo.js']))
      end

      it 'puts stylesheet files to stylesheets directory' do
        expect(
          targets(['foo.css'])
        ).to eq(Paths.new([
          'app/assets/stylesheets/foobar/foo.css.scss',
          'app/assets/stylesheets/foobar/foo.scss'
        ]))
      end

      it 'puts image files to images directory' do
        expect(
          targets(['foo.png'])
        ).to eq(Paths.new(['app/assets/images/foobar/foo.png']))
      end

      it 'ignores minified files' do
        expect(
          targets(['foo.min.js', 'foo.js'])
        ).to eq(Paths.new(['app/assets/javascripts/foobar/foo.js']))
      end

      it 'ignores gzip, map and nuspec files' do
        expect(
          targets(['foo.min.js.gzip', 'foo.js.nuspec', 'foo.js.map', 'foo.nuspec.js'])
        ).to eq(Paths.new(['app/assets/javascripts/foobar/foo.nuspec.js']))
      end

      it 'ignores bower.json' do
        expect(
          targets(['bower.json', 'foo.json'])
        ).to eq(Paths.new(['app/assets/documents/foobar/foo.json']))
      end

      it 'ignores node_modules' do
        expect(
          targets(['dist/node_modules/foo.js', 'foo.json'])
        ).to eq(Paths.new(['app/assets/documents/foobar/foo.json']))
      end

      it 'leaves minified files that dont have unminified versions' do
        expect(
          targets(['foo.min.js'])
        ).to eq(Paths.new(['app/assets/javascripts/foobar/foo.min.js']))
      end

      it 'generates manifest for javascript files' do
        expect(
          targets(['foo.js'], ['foo.js'])
        ).to eq(Paths.new([
          'app/assets/javascripts/foobar/foo.js',
          'app/assets/javascripts/foobar.js'
        ]))
      end

      it 'generates proper javascript manifest' do
        expect(
          mappings(
            ['foo.js'], ['foo.js']
          )['app/assets/javascripts/foobar.js']
        ).to include('require foobar/foo.js')
      end

      it 'generates manifest for stylesheet files' do
        expect(
          targets(['foo.css'], ['foo.css'])
        ).to eq(Paths.new([
          'app/assets/stylesheets/foobar/foo.css.scss',
          'app/assets/stylesheets/foobar/foo.scss',
          'app/assets/stylesheets/foobar.scss'
        ]))
      end

      it 'generates proper stylesheet manifest' do
        expect(
          mappings(
            ['foo.css'], ['foo.css']
          )['app/assets/stylesheets/foobar.scss']
        ).to include("@import 'foobar/foo.css.scss';")
      end

      it 'generates proper stylesheet manifest (font-awesome case)' do
        maps = mappings(
          ['css/foo.css', 'scss/foo.scss'], ['css/foo.css']
        )['app/assets/stylesheets/foobar.scss']

        expect(maps).to include("@import 'foobar/foo.css.scss';")
      end

      it 'generates proper stylesheet manifest (multple requires)' do
        maps = mappings(
          ['css/foo.css', 'scss/foo.scss'],
          ['css/foo.css', 'scss/foo.scss'],
        )['app/assets/stylesheets/foobar.scss']

        expect(maps).to include("@import 'foobar/css/foo.css.scss';")
        expect(maps).to include("@import 'foobar/scss/foo.scss';")
      end

      it 'flattens paths for if main javascript is set' do
        expect(
          targets(['dist/foo.js'], ['dist/foo.js'])
        ).to eq(Paths.new([
          'app/assets/javascripts/foobar/foo.js',
          'app/assets/javascripts/foobar.js'
        ]))
      end

      it 'flattens paths for if main stylesheet is set' do
        expect(
          targets(['dist/css/foo.css'], ['dist/css/foo.css'])
        ).to eq(Paths.new([
          'app/assets/stylesheets/foobar/foo.css.scss',
          'app/assets/stylesheets/foobar/foo.scss',
          'app/assets/stylesheets/foobar.scss'
        ]))
      end

      it 'flattens paths separately for js and css assets' do
        expect(
          targets(
            ['dist/css/foo.css', 'dist/js/foo.js'],
            ['dist/css/foo.css', 'dist/js/foo.js']
          )
        ).to eq(Paths.new([
          'app/assets/javascripts/foobar/foo.js',
          'app/assets/javascripts/foobar.js',
          'app/assets/stylesheets/foobar/foo.css.scss',
          'app/assets/stylesheets/foobar/foo.scss',
          'app/assets/stylesheets/foobar.scss'
        ]))
      end

      it 'preserves paths of other asset type if only one main' do
        expect(
          targets(
            ['dist/css/foo.css', 'dist/js/foo.js'],
            ['dist/css/foo.css']
          )
        ).to eq(Paths.new([
          'app/assets/javascripts/foobar/dist/js/foo.js',
          'app/assets/stylesheets/foobar/foo.css.scss',
          'app/assets/stylesheets/foobar/foo.scss',
          'app/assets/stylesheets/foobar.scss'
        ]))
      end

      it 'transforms all css files to scss ones to support asset urls' do
        expect(
          targets(['foo.css'])
        ).to eq(Paths.new([
          'app/assets/stylesheets/foobar/foo.css.scss',
          'app/assets/stylesheets/foobar/foo.scss'
        ]))
      end

      it 'it excludes all files in special directories like test or docs' do
        expect(
          targets([
            'test/foo.coffee',
            'test/foo/bar.js',
            'spec/foo.js',
            'perf/foo.js',
            'docs/README.md',
            'examples/foo/bar.js',
            'min/foo.js'
          ])
        ).to eq(Paths.new())
      end

      it 'it leaves main files in special directories' do
        expect(
          targets([
            'test/foo.coffee',
            'test/foo/bar.js',
            'spec/foo.js',
            'perf/foo.js',
            'docs/README.md',
            'examples/foo/bar.js',
            'min/bar/foo.js',
            'min/bar/foo-require.js'
          ], ['min/bar/foo.js'])
        ).to eq(Paths.new([
          'app/assets/javascripts/foobar/foo-require.js',
          'app/assets/javascripts/foobar/foo.js',
          'app/assets/javascripts/foobar.js'
        ]))
      end
    end

    context '#process_transformations!' do
      it 'removes sourcemaps from css files' do
        transformations = Hash[[
          [Path.new('style-old.css'), Path.new('style-new.css')]
        ]]

        input = <<-CSS.strip_heredoc
          @media print {
            .hidden-print {
              display: none !important;
            }
          }
          /*# sourceMappingURL=bootstrap.css.map */
        CSS

        output = <<-CSS.strip_heredoc
          @media print {
            .hidden-print {
              display: none !important;
            }
          }
        CSS

        File.write('/tmp/style-old.css', input)
        Transformer.process_transformations!(transformations, '/tmp', '/tmp')
        expect(File.read('/tmp/style-new.css')).to eq(output)
      end

      it 'removes sourcemaps from css files' do
        transformations = Hash[[
          [Path.new('style-old.css'), Path.new('style-new.css')]
        ]]

        input = """
        @media print {
          .hidden-print {
            display: none !important;
          }
        }
        /*# sourceMappingURL=bootstrap.css.map */""".strip_heredoc

        output = """
        @media print {
          .hidden-print {
            display: none !important;
          }
        }
        """.strip_heredoc

        File.write('/tmp/style-old.css', input)
        Transformer.process_transformations!(transformations, '/tmp', '/tmp')
        expect(File.read('/tmp/style-new.css')).to eq(output)
      end

      it 'removes sourcemaps from js files (no trailing newline)' do
        transformations = Hash[[
          [Path.new('style-old.js'), Path.new('style-new.js')]
        ]]

        input = """
        function () {
          return 'asda';
        }
        //# sourceMappingURL=angular.min.js.map""".strip_heredoc

        output = """
        function () {
          return 'asda';
        }
        """.strip_heredoc

        File.write('/tmp/style-old.js', input)
        Transformer.process_transformations!(transformations, '/tmp', '/tmp')
        expect(File.read('/tmp/style-new.js')).to eq(output)
      end

      it 'removes sourcemaps from js files (trailing newline)' do
        transformations = Hash[[
          [Path.new('style-old.js'), Path.new('style-new.js')]
        ]]

        input = """
        function () {
          return 'asda';
        }
        //# sourceMappingURL=angular.min.js.map
        """.strip_heredoc

        output = """
        function () {
          return 'asda';
        }
        """.strip_heredoc

        File.write('/tmp/style-old.js', input)
        Transformer.process_transformations!(transformations, '/tmp', '/tmp')
        expect(File.read('/tmp/style-new.js')).to eq(output)
      end

      it 'removes sourcemaps from js files (old syntax)' do
        transformations = Hash[[
          [Path.new('style-old.js'), Path.new('style-new.js')]
        ]]

        input = """
        function () {
          return 'asda';
        }
        //@ sourceMappingURL=angular.min.js.map
        """.strip_heredoc

        output = """
        function () {
          return 'asda';
        }
        """.strip_heredoc

        File.write('/tmp/style-old.js', input)
        Transformer.process_transformations!(transformations, '/tmp', '/tmp')
        expect(File.read('/tmp/style-new.js')).to eq(output)
      end

      it 'leaves code that only looks like sourcemap (react)' do

        transformations = Hash[[
          [Path.new('style-old.js'), Path.new('style-new.js')]
        ]]


        input = "
        return (
          transformed.code +
          '\\n//# sourceMappingURL=data:application/json;base64,' +
          buffer.Buffer(JSON.stringify(map)).toString('base64')
        );
        "

        File.write('/tmp/style-old.js', input)
        Transformer.process_transformations!(transformations, '/tmp', '/tmp')
        expect(File.read('/tmp/style-new.js')).to eq(input)
      end

      it 'does not remove utf-8 characters (e.g. d3 library)' do
        transformations = Hash[[
          [Path.new('style-old.js'), Path.new('style-new.js')]
        ]]

        input = "var ε = 1e-6, ε2 = ε * ε, π = Math.PI, τ = 2 * π, τε = τ - ε, halfπ = π / 2, d3_radians = π / 180, d3_degrees = 180 / π;"

        File.write('/tmp/style-old.js', input)
        Transformer.process_transformations!(transformations, '/tmp', '/tmp')
        expect(File.read('/tmp/style-new.js')).to eq(input)
      end

      it 'does remove invalid utf-8 characters in JS' do
        transformations = Hash[[
          [Path.new('style-old.js'), Path.new('style-new.js')]
        ]]

        input = File.read(Rails.root.join('spec/invalid-utf8.txt'))

        File.write('/tmp/style-old.js', input)
        Transformer.process_transformations!(transformations, '/tmp', '/tmp')
        # Following fails for invalid utf-8
        File.read('/tmp/style-new.js').gsub('foo', 'bar')
      end

      it 'does remove invalid utf-8 characters in CSS' do
        transformations = Hash[[
          [Path.new('style-old.css'), Path.new('style-new.css')]
        ]]

        input = File.read(Rails.root.join('spec/invalid-utf8.txt'))

        File.write('/tmp/style-old.css', input)
        Transformer.process_transformations!(transformations, '/tmp', '/tmp')
        # Following fails for invalid utf-8
        File.read('/tmp/style-new.css').gsub('foo', 'bar')
      end

      it 'transforms urls in css files' do
        source_file = Path.new('style.css')
        target_file = Path.new('style.scss')

        transformations = Hash[[
          [source_file, target_file],
          [Path.new('foo/bar.png'), Path.new('app/assets/images/foo.png')],
          [Path.new('foo/before.png'), Path.new('app/assets/images/before.png')],
          [Path.new('foo/around.png'), Path.new('app/assets/images/around.png')],
          [Path.new('foo/after.png'), Path.new('app/assets/images/after.png')],
          [Path.new('foo/spam.eot'), Path.new('app/assets/fonts/spam.eot')],
          [Path.new('foo/spam.woff'), Path.new('app/assets/fonts/spam.woff')],
          [Path.new('foo/spam.woff2'), Path.new('app/assets/fonts/spam.woff2')],
          [Path.new('foo/spam.ttf'), Path.new('app/assets/fonts/spam.ttf')],
          [Path.new('foo/spam.otf'), Path.new('app/assets/fonts/spam.otf')],
          [Path.new('foo/spam.svg'), Path.new('app/assets/fonts/spam.svg')]
        ]]

        css_sample = <<-CSS.gsub(/^ {8}/, '')
        @font-family {
          src:url('foo/spam.eot'); /* IE9 Compat Modes */
          src: url('foo/spam.eot?#iefix') format('embedded-opentype'), /* IE6-IE8 */
               url('foo/spam.woff') format('woff'),
               url('foo/spam.woff2') format('woff2'),url('foo/spam.ttf')  format('truetype'), /* Safari, Android, iOS */
               \n\nurl('foo/spam.otf')  format('opentype'),/**/url('foo/spam.svg#svgFontName') format('svg'); /* Legacy iOS */
          }
        }
        body{background-image:url(foo/bar.png)}
        body{background-image:url( foo/before.png)}
        body{background-image:url( foo/around.png )}
        body{background-image:url(foo/after.png )}
        CSS

        File.write('/tmp/style.css', css_sample)
        FileUtils.mkdir_p('/tmp/foo')
        File.write('/tmp/foo/bar.png', "BINARY")
        File.write('/tmp/foo/before.png', "BINARY")
        File.write('/tmp/foo/around.png', "BINARY")
        File.write('/tmp/foo/after.png', "BINARY")
        %w(eot woff2 woff ttf otf svg).each do |font_ext|
          File.write("/tmp/foo/spam.#{font_ext}", "BINARY")
        end

        Transformer.process_transformations!(transformations, '/tmp', '/tmp')
        actual_content = File.read('/tmp/style.scss')
        [
          'background-image:image-url("foo.png")',
          'background-image:image-url("before.png")',
          'background-image:image-url("around.png")',
          'background-image:image-url("after.png")',
          'src:font-url("spam.eot")',
          'src: font-url("spam.eot?#iefix") format(\'embedded-opentype\')',
          'font-url("spam.woff") format(\'woff\')',
          'font-url("spam.woff2") format(\'woff2\')',
          ',font-url("spam.ttf")  format(\'truetype\')',
          "\n\nfont-url(\"spam.otf\")  format('opentype')",
          '/**/font-url("spam.svg#svgFontName") format(\'svg\')',
        ].each do |content|
          expect(actual_content).to include(content)
        end
      end
    end

    context '#transform_relative_path' do
      it 'properly transforms relative path' do
        expect(Transformer.transform_relative_path(:images,
          Path.new('../images/image.png'), Path.new('dist/css/foobar.css'),
          Hash[[
            [Path.new('./dist/css/foobar.css'), Path.new('css/foobar.css')],
            [Path.new('./dist/images/image.png'), Path.new('app/assets/images/fiz/img.png')],
            [Path.new('./dist/image.png'), Path.new('app/assets/images/fuz/img.png')]
          ]]
        )).to eq(Path.new('fiz/img.png'))
      end
    end

    context '#transform_filename' do
      it 'leaves less extension' do
        filename = Transformer.transform_filename(
          'jquery.cookie.less'
        )

        expect(filename).to eq('jquery.cookie.less')
      end

      it 'leaves sass extension' do
        filename = Transformer.transform_filename(
          'jquery.cookie.sass'
        )

        expect(filename).to eq('jquery.cookie.sass')
      end

      it 'converts css extension to scss' do
        filename = Transformer.transform_filename(
          'jquery.cookie.css'
        )

        expect(filename).to eq('jquery.cookie.css.scss')
      end

      it 'leaves all non-custom extension' do
        filename = Transformer.transform_filename(
          'jquery.js.cookie.css.scss'
        )

        expect(filename).to eq('jquery.js.cookie.css.scss')
      end

      it 'also deals with paths' do
        filename = Transformer.transform_filename(
          '/foo/bar/jquery.cookie.sass'
        )

        expect(filename).to eq('/foo/bar/jquery.cookie.sass')
      end

      it 'deals with Path object' do
        filename = Transformer.transform_filename(
          Path.new('/jquery.cookie.sass')
        )

        expect(filename).to eq('/jquery.cookie.sass')
      end
    end
  end
end
