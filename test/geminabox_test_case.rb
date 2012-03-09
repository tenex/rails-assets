require 'minitest/unit'
require 'timeout'
require 'socket'
require 'rack'
require 'uri'
require 'fileutils'
require 'tempfile'
require 'webrick'
require 'logger'
require 'rack/auth/abstract/handler'
require 'rack/auth/abstract/request'

class Geminabox::TestCase < MiniTest::Unit::TestCase
  class << self
    # DSL
    def url(url = nil)
      @url ||= url || "http://localhost/"
    end

    def data(data = nil)
      @data ||= data || "/tmp/geminabox-test-data"
    end

    def app(&block)
      @app = block || @app || lambda{|builder| run Geminabox }
    end

    def to_app
      Rack::Builder.app(&app)
    end

    def test(test_name, &block)
      define_method "test: #{test_name} ", &block
    end

    def should_push_gem(gemname = :example, *args)
      test("can push #{gemname}") do
        assert_can_push(gemname, *args)
        assert File.exists?( File.join(config.data, "gems", File.basename(gem_file(gemname, *args)) ) ), "Gemfile not in data dir."
      end
    end


    def url_with_port(port)
      uri = URI.parse url
      uri.port = port
      uri.to_s
    end

  end

  def setup
    super
    start_app!
  end

  def teardown
    stop_app!
    super
  end



  def config
    self.class
  end

  def url_for(path)
    @url_with_port ||= config.url_with_port(@test_server_port).gsub(%r{/$}, "")
    path = "/#{path}" unless path.start_with? "/"
    @url_with_port + path
  end

  FAKE_HOME = "/tmp/geminabox-test-home"
  def self.setup_fake_home!
    return if @setup_fake_home
    @setup_fake_home = true
    FileUtils.rm_rf(FAKE_HOME)
    FileUtils.mkdir_p("#{FAKE_HOME}/gems")
    FileUtils.mkdir_p("#{FAKE_HOME}/specifications")

    FileUtils.ln_s(fixture("geminabox-9999.0.0.gemspec"), "#{FAKE_HOME}/specifications/geminabox-9999.0.0.gemspec")
    FileUtils.ln_s(fixture("../.."), "#{FAKE_HOME}/gems/geminabox-9999.0.0.gem")
  end

  def geminabox_push(gemfile)
    Geminabox::TestCase.setup_fake_home!
    command = "GEM_HOME=#{FAKE_HOME} gem inabox #{gemfile} -g '#{config.url_with_port(@test_server_port)}' 2>&1"
    output = ""
    IO.popen(command, "r") do |io|
      data = io.read
      output << data
    end
    output
  end

  def assert_can_push(gemname = :example, *args)
    assert_match /Gem .* received and indexed./, geminabox_push(gem_file(gemname, *args))
  def self.fixture(path)
    File.join(File.expand_path("../fixtures", __FILE__), path)
  end

  def fixture(*args)
    self.class.fixture(*args)
  end

  def start_app!
    @test_server_port = 7000 + rand(1000)

    FileUtils.rm_rf("/tmp/geminabox-test-data")
    FileUtils.mkdir("/tmp/geminabox-test-data")

    @app_server = fork do
      Kernel.class_eval do
        alias geminabox_old_require require
        def require(*args)
          if geminabox_old_require(*args)
            p args
          end
        end
      end
      STDERR.reopen("/dev/null")
      STDOUT.reopen("/dev/null")
      Geminabox.data = config.data
      Rack::Server.start(:app => config.to_app, :Port => @test_server_port)
      exit
    end

    Timeout.timeout(10) do
      begin
        Timeout.timeout(1) do
          TCPSocket.open("127.0.0.1", @test_server_port).close
        end
      rescue Errno::ECONNREFUSED
        sleep 0.05
        retry
      end
    end  
  end

  def stop_app!
    Process.kill(9, @app_server) if @app_server
  end

  module GemFactory
    def gem_file(name, options = {})
      version = options[:version] || "1.0.0"

      dependincies = options.fetch(:deps, {}).collect do |dep, requirement|
        dep = [*dep]
        gem_file(*dep)
        if requirement
          "s.add_dependency(#{dep.first.to_s.inspect}, #{requirement.inspect})"
        else
          "s.add_dependency(#{dep.first.to_s.inspect})"
        end
      end.join("\n")

      name = name.to_s
      path = "/tmp/geminabox-fixtures/#{name}-#{version}.gem"
      FileUtils.mkdir_p File.dirname(path)

      unless File.exists? path 
        spec = %{
          Gem::Specification.new do |s|
            s.name              = #{name.inspect}
            s.version           = #{version.inspect}
            s.summary           = #{name.inspect}
            s.description       = s.summary + " description"
            s.author            = 'Test'
            s.files             = []
            #{dependincies}
          end
        }

        spec_file = Tempfile.open("spec") do |tmpfile|
          tmpfile << spec
          tmpfile.close

          Dir.chdir File.dirname(path) do
            system "gem build #{tmpfile.path}"
          end
        end

        raise "Failed to build gem #{name}" unless File.exists? path
      end
      path
    end

    extend self
  end

  def gem_file(*args)
    GemFactory.gem_file(*args)
  end

end


