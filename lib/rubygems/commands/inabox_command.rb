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
    url = URI.join(geminabox_host, "upload")

    # sanitize printed URL if a password is present
    url_for_presentation = url.clone
    url_for_presentation.password = '***' if url_for_presentation.password

    @gemfiles.each do |gemfile|
      say "Pushing #{File.basename(gemfile)} to #{url_for_presentation}..."

      File.open(gemfile, "rb") do |file|
        response = HTTPClient.new.post(url, {'file' => file}, :follow_redirect => true)

        if response.status == 200
          say response.body
        else
          raise "Error pushing to #{url_for_presentation}: #{response.code} #{response.reason}\n\n#{response.body}"
        end
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
