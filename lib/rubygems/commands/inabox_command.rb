require 'uri'
require 'yaml'
require 'httpclient'

class Gem::Commands::InaboxCommand < Gem::Command
  def description
    'Push a gem up to your GemInABox'
  end

  def arguments
    "GEM       built gem to push up"
  end

  def usage
    "#{program_name} GEM"
  end

  def initialize
    super 'inabox', description

    add_option('-c', '--configure', "Configure GemInABox") do |value, options|
      options[:configure] = true
    end

    add_option('-g', '--host HOST', "Host to upload to.") do |value, options|
      options[:host] = value
    end
  end

  def execute
    return configure if options[:configure]
    setup
    send_gem
  end

  def setup
    if options[:args].size == 0
      @gemfiles = [find_gem]
    else
      @gemfiles = get_all_gem_names
    end
    configure unless geminabox_host
  end

  def find_gem
    say "You didn't specify a gem, looking for one in pkg..."
    path, directory = File.split(Dir.pwd)
    possible_gems = Dir.glob("pkg/#{directory}-*.gem")
    raise Gem::CommandLineError, "Couldn't find a gem in pkg, please specify a gem name on the command line (e.g. gem inabox GEMNAME)" unless possible_gems.any?
    name_regexp = Regexp.new("^pkg/#{directory}-")
    possible_gems.sort_by{ |a| Gem::Version.new(a.sub(name_regexp,'')) }.last
  end

  def send_gem
    url = URI.parse(geminabox_host)
    username, password = url.user, url.password
    url.user = url.password = nil
    url.path = ([""] + url.path.sub(/^\//, '').split("/") + ["upload"]).join("/")
    url = url.to_s

    client = HTTPClient.new
    client.set_auth(url, username, password) if username or password
    client.www_auth.basic_auth.challenge(url) # Workaround: https://github.com/nahi/httpclient/issues/63

    @gemfiles.each do |gemfile|
      say "Pushing #{File.basename(gemfile)} to #{url}..."

      response = client.post(url, {'file' => File.open(gemfile, "rb")}, {'Accept' => 'text/plain'})

      if response.status < 400
        say response.body
      else
        alert_error "Error (#{response.code} received)\n\n#{response.body}"
        terminate_interaction(1)
      end
    end

  end

  def config_path
    File.join(Gem.user_home, '.gem', 'geminabox')
  end

  def configure
    say "Enter the root url for your personal geminabox instance. (E.g. http://gems/)"
    host = ask("Host:")
    self.geminabox_host = host
  end

  def geminabox_host
    @geminabox_host ||= options[:host] || Gem.configuration.load_file(config_path)[:host]
  end

  def geminabox_host=(host)
    config = Gem.configuration.load_file(config_path).merge(:host => host)

    dirname = File.dirname(config_path)
    Dir.mkdir(dirname) unless File.exists?(dirname)

    File.open(config_path, 'w') do |f|
      f.write config.to_yaml
    end
  end

end
