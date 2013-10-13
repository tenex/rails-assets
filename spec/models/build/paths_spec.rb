require 'spec_helper'

module Build
  describe Paths do

    it 'behaves like an array' do
      expect(Paths.new + Paths.new).to be_a(Paths)
    end

    context '#new' do
      it 'accepts no arguments' do
        expect(Paths.new).to be_an(Array)
      end

      it 'accepts nil' do
        expect(Paths.new(nil)).to be_an(Array)
      end

      it 'accepts list of string paths' do
        paths = Paths.new(['./foo/bar/baz', './foo/bar'])
        expect(paths.size).to eq(2)
      end

      it 'accepts list of paths' do
        paths = Paths.new([Pathname.new('./foo/bar/baz')])
        expect(paths.size).to eq(1)
      end

      context 'accepts another Build::Paths' do
        let(:paths) { Paths.new(['./foo/bar/baz', './foo/bar']) }
        let(:paths_dup) { Paths.new(paths) }

        specify { expect(paths_dup).to eq(paths) }
        specify { expect(paths_dup).to_not be(paths) }

        context 'when new Paths object is modified' do
          let(:paths_mod) {
            paths_dup.tap { |p| p[0] = Pathname.new("") }
          }

          specify { expect(paths_mod).to_not eq(paths) }
          specify { expect(paths_mod).to_not be(paths) }
          specify { expect(paths_mod).to_not be(paths[0]) }
          specify { expect(paths_mod).to_not be(paths[1]) }
        end
      end

      it 'converts paths to Build::Path' do
        paths = Paths.new(['./foo/bar/baz', './foo/bar'])
        expect(paths.first.class).to eq(Build::Path)
      end

      it 'removes duplicate paths' do
        paths = Paths.new(['./foo/bar', './foo/bar'])
        expect(paths.size).to eq(1)
      end

      it 'normalizes paths' do
        paths = Paths.new(['foo/bar', './foo/bar'])
        expect(paths.size).to eq(1)
      end

      it 'handles mixed array value types' do
        paths = Paths.new(['foo/bar', Pathname.new('./foo/bar')])
        expect(paths.size).to eq(1)
      end

      it 'handles empty paths' do
        paths = Paths.new(['', '.'])
        expect(paths.size).to eq(1)
      end
    end

    context '#from' do
      it 'fetches all files from given directory' do
        FileUtils.mkdir_p('/tmp/testing/foo')
        FileUtils.touch('/tmp/testing/foo/file.txt')
        FileUtils.touch('/tmp/testing/foo/file.js')
        expect(Paths.from('/tmp/testing').size).to eq 2
      end
    end

    context '#select' do
      let(:javascript_paths) {
        Paths.new([
          'foo.js', 'foo.coffee', 'foo/bar.js.coffee',
          'foo.js.one', 'foo.coffee.two', 'foo.js.coffee.three'
        ])
      }

      let(:stylesheet_paths) {
        Paths.new([
          'foo.css', 'foo.less', 'foo.css.less', 'foo.scss',
          'foo.css.scss', 'foo.sass', 'foo.css.sass',
          'foo/bar.css.scss', 'foo/bar.css.less',
          'foo.css.one', 'foo.scss.two', 'foo.sass.three',
          'foo.css.less.four'
        ])
      }

      let(:image_paths) {
        Paths.new([
          'foo.png', 'foo.gif', 'foo.jpeg', 'foo.jpg',
          'foo/bar/baz.png', 'foo/fiz/fuz.gif'
        ])
      }

      let(:strange_paths) {
        Paths.new([
          'foo.pnga', 'foo.css3', 'foo.jsv', 'foo.js2',
          'foo/bar/baz.exe', 'foo/fiz/fuz.rb', 
          'FOO.JS', 'foo.Coffee', 'foo.Js'
        ])
      }

      let(:asset_paths) { 
        javascript_paths + stylesheet_paths +
        image_paths + strange_paths
      }

      it 'can filter out all javascript assets' do
        expect(asset_paths.select(&:javascript?)).
          to eq(javascript_paths)
      end

      it 'can filter out all stylesheet assets' do
        expect(asset_paths.select(&:stylesheet?)).
          to eq(stylesheet_paths)
      end

      it 'can filter out all image assets' do
        expect(asset_paths.select(&:image?)).
          to eq(image_paths)
      end

      it 'is able to drop non-existent paths' do
        expect(
          Paths.new(%w(/tmp /dungedon)).select(&:exist?).size
        ).to eq(1)
      end
    end

    context '#except_minified' do
      let(:minified_paths) {
        Paths.new([
          'foo.min.js', 'foo.min.css'
        ])
      }

      let(:normal_paths) {
        Paths.new([
          'foo.js', 'foo.css', 'foo.smin', 'foo.mins',
          'foo.js.min', 'foo/bar.css.min', 'foo/bar.js.min',
          'min.js', 'min.coffee'
        ])
      }

      let(:asset_paths) { minified_paths + normal_paths }

      it 'can filter out all minified files' do
        expect(asset_paths.reject(&:minified?)).
          to eq(normal_paths)
      end
    end
  end
end
