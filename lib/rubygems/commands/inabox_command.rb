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
  end

  def execute
    return configure if options[:configure]
    setup
    send_gem
  end

  def setup
    @gemfile = get_one_gem_name
    configure unless geminabox_host
  end

  def send_gem
    say "Pushing gem to #{geminabox_host}..."

    File.open(@gemfile, "rb") do |file|
      url = URI.parse(geminabox_host)
      query, headers = Multipart::MultipartPost.new.prepare_query("file" => file)

      Net::HTTP.start(url.host, url.port) {|con|
        con.read_timeout = 5
        response = con.post("/upload", query, headers)
        puts response.body
      }
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
    geminabox_host ||= Gem.configuration.load_file(config_path)[:host]
  end

  def geminabox_host=(host)
    config = Gem.configuration.load_file(config_path).merge(:host => host)

    dirname = File.dirname(config_path)
    Dir.mkdir(dirname) unless File.exists?(dirname)

    File.open(config_path, 'w') do |f|
      f.write config.to_yaml
    end
  end

  module Multipart
    require 'rubygems'
    require 'mime/types'
    require 'net/http'
    require 'cgi'

    class Param
      attr_accessor :k, :v
      def initialize( k, v )
        @k = k
        @v = v
      end

      def to_multipart
        return "Content-Disposition: form-data; name=\"#{k}\"\r\n\r\n#{v}\r\n"
      end
    end

    class FileParam
      attr_accessor :k, :filename, :content
      def initialize( k, filename, content )
        @k = k
        @filename = filename
        @content = content
      end

      def to_multipart
        return "Content-Disposition: form-data; name=\"#{k}\"; filename=\"#{filename}\"\r\n" + "Content-Transfer-Encoding: binary\r\n" + "Content-Type: #{MIME::Types.type_for(@filename)}\r\n\r\n" + content + "\r\n"
      end
    end

    class MultipartPost
      BOUNDARY = 'tarsiers-rule0000'
      HEADER = {"Content-type" => "multipart/form-data, boundary=" + BOUNDARY + " "}

      def prepare_query(params)
        fp = []
        params.each {|k,v|
          if v.respond_to?(:read)
            fp.push(FileParam.new(k, v.path, v.read))
          else
            fp.push(Param.new(k,v))
          end
        }
        query = fp.collect {|p| "--" + BOUNDARY + "\r\n" + p.to_multipart }.join("") + "--" + BOUNDARY + "--"
        return query, HEADER
      end
    end  
  end
end
