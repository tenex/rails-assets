require 'sinatra/base'
require 'rubygems'
require "rubygems/indexer"

require 'hostess'

class Gembox < Sinatra::Base
  set :sessions, true
  set :public, File.join(File.dirname(__FILE__), *%w[.. public])
  set :data, File.join(File.dirname(__FILE__), *%w[.. data])
  use Hostess, self.data

  enable :static

  get '/' do
    begin
      @gems = Marshal.load(Gem.gunzip(Gem.read_binary( File.join(options.data, "specs.#{Gem.marshal_version}.gz")) ))
    rescue
      @gems = []
    end

    erb :index
  end

  get '/upload' do
    erb :upload
  end

  post '/upload' do
    unless params[:file] && (tmpfile = params[:file][:tempfile]) && (name = params[:file][:filename])
      @error = "No file selected"
      return erb(:upload)
    end

    Dir.mkdir(File.join(options.data, "gems")) unless File.directory? File.join(options.data, "gems")

    File.open(File.join(options.data, "gems", File.basename(name)), "w") do |f|
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
