require "builder"
require 'sinatra/base'
require 'rubygems'
require "rubygems/indexer"

require 'hostess'


class Geminabox < Sinatra::Base
  enable :static, :methodoverride

  set :public, File.join(File.dirname(__FILE__), *%w[.. public])
  set :data, File.join(File.dirname(__FILE__), *%w[.. data])
  set :views, File.join(File.dirname(__FILE__), *%w[.. views])
  use Hostess

  autoload :GemVersionCollection, "geminabox/gem_version_collection"

  get '/' do
    @gems = load_gems
    erb :index
  end

  get '/upload' do
    erb :upload
  end

  delete '/gems/*.gem' do
    File.delete file_path if File.exists? file_path
    reindex
    redirect "/"
  end

  post '/upload' do
    unless params[:file] && (tmpfile = params[:file][:tempfile]) && (name = params[:file][:filename])
      @error = "No file selected"
      return erb(:upload)
    end

    tmpfile.binmode

    Dir.mkdir(File.join(options.data, "gems")) unless File.directory? File.join(options.data, "gems")

    File.open(File.join(options.data, "gems", File.basename(name)), "wb") do |f|
      while blk = tmpfile.read(65536)
        f << blk
      end
    end
    reindex
    redirect "/"
  end

private
  def reindex
    Gem::Indexer.new(options.data).generate_index
  end

  def file_path
    File.expand_path(File.join(options.data, *request.path_info))
  end

  def load_gems
    %w(specs prerelease_specs).inject(GemVersionCollection.new){|gems, specs_file_type|
      specs_file_path = File.join(options.data, "#{specs_file_type}.#{Gem.marshal_version}.gz")
      if File.exists?(specs_file_path)
        gems + Marshal.load(Gem.gunzip(Gem.read_binary(specs_file_path)))
      else
        gems
      end
    }
  end

  helpers do
    def url_for(path)
      url = request.scheme + "://"
      url << request.host

      if request.scheme == "https" && request.port != 443 ||
          request.scheme == "http" && request.port != 80
        url << ":#{request.port}"
      end

      url << path
    end
  end
end
