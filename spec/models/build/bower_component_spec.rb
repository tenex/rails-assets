require 'spec_helper'

module Build
  describe BowerComponent do
    let(:jquery_meta) {
      JSON.parse('{
        "endpoint": {
          "name": "jquery",
          "source": "git://github.com/srigi/jquery.git",
          "target": "~2.0.3"
        },
        "canonicalDir": "/Users/sheerun/Source/rails-assets/bower_components/awesome-jquery",
        "pkgMeta": {
          "name": "jquery",
          "version": "2.0.3",
          "description": "jQuery component",
          "keywords": [
            "jquery",
            "component"
          ],
          "dependencies": {
            "eventie": "desandro/eventie"
          },
          "main": "jquery.js",
          "license": "MIT",
          "homepage": "https://github.com/srigi/jquery",
          "_release": "2.0.3",
          "_resolution": {
            "type": "version",
            "tag": "2.0.3",
            "commit": "452a56b52b8f4a032256cdb8b6838f25f0bdb3d2"
          },
          "_source": "git://github.com/srigi/jquery.git",
          "_target": "~2.0.3",
          "_originalSource": "srigi/jquery",
          "_direct": true
        },
        "extraneous": true,
        "dependencies": {
          "eventie": {
            "endpoint": {
              "name": "eventie",
              "source": "awesome/eventie",
              "target": ">=1.0.3 <2.0"
            },
            "canonicalDir": "/Users/sheerun/Source/rails-assets/test-app/bower_components/eventie",
            "pkgMeta": {
              "name": "eventie",
              "version": "1.0.3",
              "main": "eventie.js",
              "description": "event binding helper",
              "homepage": "https://github.com/desandro/eventie",
              "_release": "1.0.3",
              "_resolution": {
                "type": "version",
                "tag": "v1.0.3",
                "commit": "1f43e215030d7b39be02311b49734d530ab85650"
              },
              "_source": "git://github.com/desandro/eventie.git",
              "_target": ">=1.0.3 <2.0"
            },
            "dependencies": {},
            "nrDependants": 1
          }
        },
        "nrDependants": 1,
        "versions": [
          "2.0.3",
          "2.0.2"
        ],
        "update": {
          "target": "2.0.3",
          "latest": "2.0.3"
        }
      }')
    }

    let(:strange_main) {
      JSON.parse('{
        "canonicalDir": "/Users/sheerun/Source/rails-assets/bower_components/awesome-jquery",
        "pkgMeta": {
          "main": {
            "scripts": ["jquery.js"],
            "stylesheets": "jquery.css"
          },
          "license": ["MIT", "GPL"]
        }
      }')
    }

    context '#main_paths' do
      let(:subject) {
        BowerComponent.new(Path.new('/tmp'), strange_main)
      }

      it 'parses correctly main as hash' do
        expect(subject.main).to eq([
          "jquery.js",
          "jquery.css"
        ])
      end

      it 'parses correctly licenses as array' do
        expect(subject.license).to eq([
          'MIT', 'GPL'
        ])
      end
    end

    context '#new' do
      let(:subject) {
        BowerComponent.new(Path.new('/tmp'), jquery_meta)
      }

      it 'properly generates BowerComponent' do
        expect(subject).to be_a(BowerComponent)
      end

      it 'properly extract dependencies' do
        expect(subject.dependencies).to eq({ "awesome/eventie" => ">=1.0.3 <2.0" })
      end

      it 'properly extract main files' do
        expect(subject.main).to eq(['jquery.js'])
      end

      it 'properly extracts description' do
        expect(subject.description).to eq('jQuery component')
      end

      it 'recognizes it is custom repository' do
        expect(subject.github?).to be(true)
      end

      it 'renders proper full_name' do
        expect(subject.full_name).to eq('srigi/jquery')
      end

      it 'renders proper repo' do
        expect(subject.repo).to eq('jquery')
      end

      it 'renders proper user' do
        expect(subject.user).to eq('srigi')
      end

      it 'renders proper repository' do
        expect(subject.repository).to eq('git://github.com/srigi/jquery.git')
      end

      it 'renders proper homepage' do
        expect(subject.homepage).to eq('https://github.com/srigi/jquery')
      end

      it 'render proper component_dir' do
        expect(subject.component_dir).
          to eq(Path.new('/Users/sheerun/Source/rails-assets/bower_components/awesome-jquery'))

        expect(subject.component_dir).to be_a(Path)
      end
    end

    context '#gem' do
      let(:subject) {
        BowerComponent.new(Path.new('/tmp'), jquery_meta)
      }

      it 'instantiates GemComponent delefator' do
        expect(subject.gem).to be_a(GemComponent)
      end

      it 'allows for running self methods on delegator' do
        expect(subject.gem.homepage).to eq('https://github.com/srigi/jquery')
      end

      it 'introduces new methods on gem delegator' do
        expect(subject.gem.short_name).to eq('srigi--jquery')
      end
    end

    context '#version_model' do
      let(:subject) {
        BowerComponent.new(Path.new('/tmp'), jquery_meta)
      }

      it 'returns unsaved Version model' do
        expect(subject.version_model).to be_a(Version)
        expect(subject.version_model).to be_a(Version)
      end

      it 'returns component association on Version' do
        expect(subject.version_model.component).to be_a(Component)
      end

      it 'sets proper version on Version model' do
        expect(subject.version_model.string).to eq('2.0.3')
      end

      it 'sets proper gem name on Component model' do
        expect(subject.version_model.component.name).to eq('srigi--jquery')
      end

      it 'saves both component and version when calling save! on result' do
        expect { subject.version_model.save! }.
          to change { Component.count + Version.count }.by(2)

        expect { subject.version_model.save! }.
          to change { Component.count + Version.count }.by(0)
      end
    end
  end
end
