require 'spec_helper'

module Build
  describe GemComponent do
    let(:bower_component) {
      BowerComponent.new(Path.new('/tmp'), JSON.parse('{
        "endpoint": {
          "name": "jquery",
          "source": "srigi/jquery",
          "target": "~2.0.3"
        },
        "canonicalDir": "/Users/sheerun/Source/rails-assets/bower_components/jquery",
        "pkgMeta": {
          "name": "jquery",
          "version": "2.0.3",
          "description": "jQuery component",
          "keywords": [
            "jquery",
            "component"
          ],
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
        "dependencies": {},
        "nrDependants": 1,
        "versions": [
          "2.0.3",
          "2.0.2"
        ],
        "update": {
          "target": "2.0.3",
          "latest": "2.0.3"
        }
      }'))
    }

    context '#new' do
      subject { bower_component.gem }

      its(:filename) { should == 'rails-assets-srigi--jquery-2.0.3.gem' }
      its(:name) { should == 'rails-assets-srigi--jquery' }
      its(:short_name) { should == 'srigi--jquery' }
      its(:version) { should == '2.0.3' }
      its(:module) { should == 'RailsAssetsJquery' }
    end
  end
end
