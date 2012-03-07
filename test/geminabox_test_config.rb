require "minitest/unit"
require "timeout"
require "socket"
require "rack"
require "uri"
require "fileutils"
require "tempfile"

class GeminaboxTestConfig < MiniTest::Unit::TestCase
  class << self
    attr_writer :name, :url, :data
    attr_reader :name, :app

    def to_s
      "GeminaboxTestConfig[ #{name} ] "
    end

    def url
      @url ||= "http://localhost/"
    end

    def data
      @data ||= "/tmp/geminabox-test-data"
    end

    def app(&block)
      @app = block || @app || lambda{|builder| run Geminabox }
    end

    def to_app
      Rack::Builder.app(&app)
    end

    def url_with_port(port)
      uri = URI.parse(url)
      uri.port = port
      uri.to_s
    end

    def test(test_name, &block)
      define_method "test: #{name} #{test_name} ", &block
    end

    def should_push_gem(gemname = :example)
      test("can push #{gemname}") do
        assert_can_push(gemname)
        assert File.exists?( File.join(config.data, "gems", File.basename(gem_file(gemname)) ) ), "Gemfile not in data dir."
      end
    end

    def define(name, &block)
      Class.new(self, &block).name = name
    end

  end

  def config
    self.class
  end

  def setup
    super
    start_app!
  end

  def teardown
    stop_app!
    super
  end

  def gem_file(name)
    name = name.to_s
    path = "/tmp/geminabox-fixtures/#{name}-1.0.0.gem"
    unless File.exists?( path )
      spec = Tempfile.new("spec")
      spec << %{
        Gem::Specification.new do |s|
          s.name              = #{name.inspect}
          s.version           = "1.0.0"
          s.summary           = #{name.inspect}
          s.description       = s.summary + " description"
          s.author            = 'nil'
          s.files             = []
        end
      }
      spec.close
      FileUtils.mkdir_p(File.dirname(path))
      Dir.chdir File.dirname(path) do
        system("gem build #{spec.path} 2> /dev/null > /dev/null")
      end
      raise "Failed to build gem #{name}" unless File.exists?(path)
    end
    path
  end

  def geminabox_push(gemfile)
    context_path = File.expand_path("../context/", __FILE__)
    output = ""
    IO.popen("GEM_HOME=#{context_path} gem inabox #{gemfile} -g '#{config.url_with_port(@test_server_port)}' 2>&1", "r") do |io|
      data = io.read
      output << data
    end
    output
  end

  def assert_can_push(gemname = :example)
    assert_match /Gem .* received and indexed./, geminabox_push(gem_file(gemname))
  end

  def start_app!
    @test_server_port = 7000 + rand(1000)

    FileUtils.rm_rf("/tmp/geminabox-test-data")
    FileUtils.mkdir("/tmp/geminabox-test-data")

    @app_server = fork do
      STDERR.reopen("/dev/null")
      STDOUT.reopen("/dev/null")
      Geminabox.data = config.data
      Rack::Server.start(:app => config.to_app, :Port => @test_server_port)
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

end
