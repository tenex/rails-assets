require 'uri'
require 'httpclient'

class GeminaboxClient
  attr_reader :url, :http_client

  def initialize(url)
    extract_username_and_password_from_url!(url)
    @http_client = HTTPClient.new
    @http_client.set_auth(url_for(:upload), @username, @password) if @username or @password
    @http_client.www_auth.basic_auth.challenge(url_for(:upload)) # Workaround: https://github.com/nahi/httpclient/issues/63
  end

  def extract_username_and_password_from_url!(url)
    uri = URI.parse(url.to_s)
    @username, @password = uri.user, uri.password
    uri.user = uri.password = nil
    uri.path = uri.path + "/" unless uri.path.end_with?("/")
    @url = uri.to_s
  end

  def url_for(path)
    url + path.to_s
  end

  def push(gemfile)
    response = http_client.post(url_for(:upload), {'file' => File.open(gemfile, "rb")}, {'Accept' => 'text/plain'})

    if response.status < 400
      response.body
    else
      raise GeminaboxClient::Error, "Error (#{response.code} received)\n\n#{response.body}"
    end
  end

end

class GeminaboxClient::Error < RuntimeError
end

module GeminaboxClient::GemLocator
  def find_gem(dir)
    gemname = File.split(dir).last
    glob_matcher = "{pkg/,}#{gemname}-*.gem"
    latest_gem_for(gemname, Dir.glob(glob_matcher)) or raise Gem::CommandLineError, NO_GEM_PROVIDED_ERROR_MESSAGE
  end

  def latest_gem_for(gemname, files)
    regexp_matcher = %r{(?:pkg/)#{gemname}-(#{Gem::Version::VERSION_PATTERN})\.gem}
    sorter = lambda{|v| Gem::Version.new(regexp_matcher.match(v)[1]) }
    files.grep(regexp_matcher).max_by(&sorter)
  end

  extend self

  NO_GEM_PROVIDED_ERROR_MESSAGE = "Couldn't find a gem in pkg, please specify a gem name on the command line (e.g. gem inabox GEMNAME)"
end
