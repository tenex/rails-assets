require 'spec_helper'

# TODO: fix this tests
describe Build::Converter do
  context 'generates proper files in conversion', slow: true do
    before { Component.destroy_all }

    def self.component(name, version = nil, opts = {}, &block)
      gem_name = opts[:gem_name] || name

      it "properly compile #{name} #{version} to #{gem_name}" do
        STDERR.puts "\n\e[34mBuilding package #{name} #{version}\e[0m"

        version = Build::Converter.run!(name, version)

        @gem_root = File.join(Figaro.env.data_dir, 'gems',
          "rails-assets-#{version.component.name}-#{version.string}").to_s

        gem_path = @gem_root + '.gem'

        expect(File.exist?(gem_path.to_s)).to be_true
        Build::Utils.sh(File.join(Figaro.env.data_dir, 'gems'), 'gem unpack', gem_path.to_s)
        expect(Dir.exist?(@gem_root.to_s)).to be_true

        instance_eval(&block)

        @component = Component.where(:name => gem_name).first
        @component.should_not be_nil
      end
    end

    def log(msg, color = 0)
      STDERR.puts "\e[#{color}m--> #{msg}\e[0m"
    end

    def gem_file(path)
      ex = File.exist?(File.join(@gem_root, path))

      log "Checking file #{path} -> #{ex ? "OK" : "NOT FOUND"}", (ex ? 32 : 31)
      unless ex
        dir = File.join(@gem_root, "**", "*")
        log "Existing files: #{dir}"
        Dir[dir].each do |f|
          STDERR.puts " - #{f}"
        end
      end

      expect(ex).to eq true
    end

    def file_contains(path, fragment)
      log "Checking contents of #{path}"
      contents = File.read(File.join(@gem_root, path))
      expect(contents).to include(fragment)
    end

    component "angular", "1.2.0-rc.1" do
      gem_file "vendor/assets/javascripts/angular.js"
      gem_file "vendor/assets/javascripts/angular/angular.js"
    end

    component "angular", "1.0.7" do
      gem_file "vendor/assets/javascripts/angular.js"
      gem_file "vendor/assets/javascripts/angular/angular.js"
    end

    component "sugar", "1.3.9" do
      gem_file "vendor/assets/javascripts/sugar.js"
      gem_file "vendor/assets/javascripts/sugar/sugar-full.development.js"
      file_contains 'vendor/assets/javascripts/sugar.js', 'sugar/sugar.min'
    end

    component "purl", "2.3.1" do
      gem_file "vendor/assets/javascripts/purl.js"
      gem_file "vendor/assets/javascripts/purl/purl.js"
    end

    component "angular-mousewheel", "1.0.2" do
      gem_file "vendor/assets/javascripts/angular-mousewheel.js"
      gem_file "vendor/assets/javascripts/angular-mousewheel/mousewheel.js"
    end

    component "leaflet", "0.6.2" do
      gem_file "vendor/assets/javascripts/leaflet.js"
      gem_file "vendor/assets/javascripts/leaflet/leaflet.js"

      gem_file "vendor/assets/stylesheets/leaflet/leaflet.scss"
      gem_file "vendor/assets/stylesheets/leaflet/leaflet.ie.scss"
      gem_file "vendor/assets/stylesheets/leaflet.scss"

      gem_file "vendor/assets/images/leaflet/dist/images/layers-2x.png"
      gem_file "vendor/assets/images/leaflet/dist/images/layers.png"
      gem_file "vendor/assets/images/leaflet/dist/images/marker-icon-2x.png"
      gem_file "vendor/assets/images/leaflet/dist/images/marker-icon.png"
      gem_file "vendor/assets/images/leaflet/dist/images/marker-shadow.png"
    end

    component "resizeend", "1.1.2" do
      gem_file "vendor/assets/javascripts/resizeend.js"
      gem_file "vendor/assets/javascripts/resizeend/resizeend.js"
    end

    component "rails-assets/jquery-waypoints", nil, :gem_name => "rails-assets--jquery-waypoints" do
      gem_file "vendor/assets/javascripts/jquery-waypoints/waypoints.js"
    end

    component "selectize", '0.8.0' do
      gem_file "vendor/assets/javascripts/selectize.js"
      gem_file "vendor/assets/javascripts/selectize/selectize.js"
      gem_file "vendor/assets/stylesheets/selectize.scss"
      gem_file "vendor/assets/stylesheets/selectize/selectize.scss"
    end

    component "jquery.cookie", '1.4.0' do
      gem_file "vendor/assets/javascripts/jquery.cookie.js"
      gem_file "vendor/assets/javascripts/jquery.cookie/jquery.cookie.js"
      file_contains 'vendor/assets/javascripts/jquery.cookie.js',
        'require jquery.cookie/jquery.cookie'
    end

    component "angular-ui-tinymce", '0.0.4' do
      gem_file 'vendor/assets/javascripts/angular-ui-tinymce.js'
      gem_file 'vendor/assets/javascripts/angular-ui-tinymce/tinymce.js'
      file_contains 'rails-assets-angular-ui-tinymce.gemspec',
        'spec.add_dependency "rails-assets-jozzhart--tinymce", "4.0.0"'
    end

    component "jozzhart--tinymce", '4.0.0' do
      gem_file 'vendor/assets/javascripts/tinymce/tinymce.min.js'
      gem_file 'vendor/assets/javascripts/tinymce.js'
      file_contains 'rails-assets-jozzhart--tinymce.gemspec',
        'spec.name          = "rails-assets-jozzhart--tinymce"'
    end

    component "swipe", "2.0.0" do
      gem_file "vendor/assets/javascripts/swipe.js"
      gem_file "vendor/assets/javascripts/swipe/swipe.js"
      file_contains "vendor/assets/javascripts/swipe.js", "require swipe/swipe"
    end

    component "Swipe", "2.0.0" do
      gem_file "vendor/assets/javascripts/Swipe.js"
      gem_file "vendor/assets/javascripts/Swipe/swipe.js"
      file_contains "vendor/assets/javascripts/Swipe.js", "require Swipe/swipe"
    end

    component "isotope", "2.0.0-beta.3" do
      gem_file "vendor/assets/javascripts/isotope.js"
      gem_file "vendor/assets/javascripts/isotope/isotope.js"
      gem_file "vendor/assets/javascripts/isotope/item.js"
      gem_file "vendor/assets/javascripts/isotope/layout-mode.js"
      gem_file "vendor/assets/javascripts/isotope/layout-modes/vertical.js"

      file_contains 'rails-assets-isotope.gemspec',
        'spec.add_dependency "rails-assets-desandro--get-size", ">= 1.1.4", "< 2.0"'
    end
  end
end
