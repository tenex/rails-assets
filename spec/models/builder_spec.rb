require 'spec_helper'

describe Build::Convert do
  context 'generates proper files in conversion', slow: true do
    before { Component.destroy_all }

    def self.component(name, version = nil, opts = {}, &block)
      gem_name = opts[:gem_name] || name

      it "properly compile #{name} #{version} to #{gem_name}" do
        STDERR.puts "\n\e[34mBuilding package #{name} #{version}\e[0m"

        silence_stream(STDOUT) do
          Build::Convert.new(name, version).convert!(force: true) do |dir|
            @gem_root = File.join(dir, "gems", gem_name)
            instance_exec(&block)
          end

          Component.where(:name => gem_name).first.should_not be_nil
        end
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

      gem_file "vendor/assets/stylesheets/leaflet.css"
      gem_file "vendor/assets/stylesheets/leaflet/leaflet.ie.css"
      gem_file "vendor/assets/stylesheets/leaflet/leaflet.css"

      gem_file "vendor/assets/images/leaflet/images/layers-2x.png"
      gem_file "vendor/assets/images/leaflet/images/layers.png"
      gem_file "vendor/assets/images/leaflet/images/marker-icon-2x.png"
      gem_file "vendor/assets/images/leaflet/images/marker-icon.png"
      gem_file "vendor/assets/images/leaflet/images/marker-shadow.png"
    end

    component "resizeend", "1.1.2" do
      gem_file "vendor/assets/javascripts/resizeend.js"
      gem_file "vendor/assets/javascripts/resizeend/resizeend.js"
    end

    component "rails-assets/jquery-waypoints", nil, :gem_name => "rails-assets--jquery-waypoints" do
      gem_file "vendor/assets/javascripts/jquery-waypoints.js"
      gem_file "vendor/assets/javascripts/jquery-waypoints/waypoints.js"
    end
  end
end
