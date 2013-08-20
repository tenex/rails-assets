require File.expand_path("../../test_helper", __FILE__)

module Helper

end

describe GemBuilder do
  def self.component(name, version = nil, &block)
    define_method "test_component: #{name} #{version}" do
      STDERR.puts "\n\e[34mBuilding package #{name} #{version}\e[0m"

      # Reset
      @component = nil
      @gemspec = nil

      @component = Component.new(name, version)
      silence_stream(STDOUT) do
        Convert.new(@component).convert!(
          :io => STDOUT,
          :force => true
        ) do |dir|
          Dir.chdir(dir) do
            instance_exec(&block)
          end
        end
      end
    end
  end

  def log(msg, color = 0)
    STDERR.puts "\e[#{color}m--> #{msg}\e[0m"
  end

  def gem_file(path)
    ex = File.exist?(File.join(@component.gem_name, path))
    log "Checking file #{path} -> #{ex ? "OK" : "NOT FOUND"}", (ex ? 32 : 31)
    unless ex
      dir = File.join(@component.gem_name, "**", "*")
      log "Existing files: #{dir}"
      Dir[dir].each do |f|
        STDERR.puts " - #{f}"
      end
    end
    ex.must_equal true
  end

  component "angular", "1.0.7" do
    gem_file "vendor/assets/javascripts/angular.js"
    gem_file "vendor/assets/javascripts/angular/angular.js"
  end

  component "sugar", "1.3.9" do
    gem_file "vendor/assets/javascripts/sugar.js"
    gem_file "vendor/assets/javascripts/sugar/sugar.min.js"
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
end
