require 'sinatra/base'
require 'rubygems'


class Gembox < Sinatra::Base
  set :sessions, true
  set :public, File.join(File.dirname(__FILE__), *%w[.. public])
  enable :static

  get '/' do
    @gems = Marshal.load(Gem.gunzip(Gem.read_binary( File.join(options.public, "specs.#{Gem.marshal_version}.gz")) ))
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

    File.open(File.join(options.public, "gems", File.basename(name)), "w") do |f|
      while blk = tmpfile.read(65536)
        f << blk
      end
    end

    redirect "/"
  end

private
  def reindex
    Gem::Indexer.new(options.public).generate_index
  end
end
