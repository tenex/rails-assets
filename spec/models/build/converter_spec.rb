require 'spec_helper'

module Build
  describe Converter do
    context '#run!' do
      it 'should produce the same output when executed in parallel' do
        threads = (0..2).map do
          Thread.new do
            Converter.run!('moment-timezone', 'latest')
          end
        end

        values = threads.map(&:join).map(&:value)

        expect(values[0]).to_not eq(nil)
        expect(values[1]).to_not eq(nil)
        expect(values[2]).to_not eq(nil)

        expect(values[1]).to eq(values[0])
        expect(values[2]).to eq(values[0])
      end
    end

    context '#install!' do
      it 'installs component and return all dependencies' do
        expect {
          Converter.install! 'jquery' do |dependencies|
            expect(dependencies.size).to eq(1)
            expect(dependencies.first).to be_a(BowerComponent)
            expect(Dir.exists?(dependencies.first.component_dir)).to eq(true)
          end
        }.to change { Version.count + Component.count }.by(2)
      end
    end

    context '#convert!' do
      it 'converts component to new temp directory and yields it' do
        Converter.install!('jquery') do |dependencies|
          Converter.convert!(dependencies.first) do |dir, paths, mains|
            expect(Dir.exist?(dir.to_s)).to be_true
            expect(paths.all? { |p| File.exist?(dir.join(p)) }).to be_true
            expect(mains.all? { |p| File.exist?(dir.join(p)) }).to be_true
          end
        end
      end

      it 'raises an BuildError if converted component has no files in it' do
        Dir.mktmpdir do |dir|
          # Probably replace with fixtures
          Utils.sh(dir, 'git init')
          Utils.sh(dir, 'touch .gitignore')
          Utils.sh(dir, 'git add -f .gitignore')
          Utils.sh(dir, 'git config user.email "you@example.com"')
          Utils.sh(dir, 'git config user.name "Your Name"')
          Utils.sh(dir, 'git commit -m init')
          component = BowerComponent.new(dir, {
            'endpoint' => { 'name' => 'foobar', 'source' => 'https://github.com/sheerun/foobar' },
            'pkgMeta' => { 'name' => 'foobar' }
          })
          expect {
            Converter.convert!(component) do; end
          }.to raise_error(BuildError)
        end
      end
    end

    context '#build!' do
      it 'builds gem to given directory and returns path to it' do
        Dir.mktmpdir do |tmpdir|
          gem_path = Converter.install!('jquery') do |dependencies|
            Converter.convert!(dependencies.first) do |dir, paths, mains|
              Converter.build!(dependencies.first, dir, tmpdir)
            end
          end

          expect(File.exist?(gem_path.to_s)).to be_true
        end
      end
    end

    context '#index!' do
      it 'moves generated gems to data_dir and reindexes' do
        Dir.mktmpdir do |install_dir|
          Dir.mktmpdir do |tmpdir|
            gem_path = Converter.install!('jquery') do |dependencies|
              Converter.convert!(dependencies.first) do |dir, paths, mains|
                Converter.build!(dependencies.first, dir, tmpdir)
              end
            end

            Converter.index!([gem_path], Path.new(install_dir))
          end
        end
      end
    end

    context '#process!' do
      it 'processes given bower component' do
        Converter.process!('jquery', '2.0.3') do |versions, paths|
          expect(versions.first).to be_a(Version)
          expect(paths.first).to be_a(Path)
        end
      end
    end
  end
end
