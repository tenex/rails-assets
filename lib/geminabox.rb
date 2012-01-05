require 'rubygems'
require 'bundler/setup'

require "digest/md5"
require "builder"
require 'sinatra/base'
require 'rubygems/builder'
require "rubygems/indexer"

require 'hostess'

class Geminabox < Sinatra::Base
  enable :static, :methodoverride

  set :public_folder, File.join(File.dirname(__FILE__), *%w[.. public])
  set :data, File.join(File.dirname(__FILE__), *%w[.. data])
  set :build_legacy, true
  set :views, File.join(File.dirname(__FILE__), *%w[.. views])
  set :allow_replace, false
  use Hostess

  class << self
    def disallow_replace?
      ! allow_replace
    end

    def fixup_bundler_rubygems!
      return if @post_reset_hook_applied
      Gem.post_reset{ Gem::Specification.all = nil } if defined? Bundler and Gem.respond_to? :post_reset
      @post_reset_hook_applied = true
    end
  end

  autoload :GemVersionCollection, "geminabox/gem_version_collection"

  get '/' do
    @gems = load_gems
    @index_gems = index_gems(@gems)
    erb :index
  end

  get '/atom.xml' do
    @gems = load_gems
    erb :atom, :layout => false
  end

  get '/upload' do
    erb :upload
  end

  get '/reindex' do
    reindex
    redirect url("/")
  end

  delete '/gems/*.gem' do
    File.delete file_path if File.exists? file_path
    reindex
    redirect url("/")
  end

  post '/upload' do
    return "Please ensure #{File.expand_path(Geminabox.data)} is writable by the geminabox web server." unless File.writable? Geminabox.data
    unless params[:file] && (tmpfile = params[:file][:tempfile]) && (name = params[:file][:filename])
      @error = "No file selected"
      return erb(:upload)
    end

    tmpfile.binmode

    Dir.mkdir(File.join(settings.data, "gems")) unless File.directory? File.join(settings.data, "gems")

    dest_filename = File.join(settings.data, "gems", File.basename(name))


    if Geminabox.disallow_replace? and File.exist?(dest_filename)
      existing_file_digest = Digest::SHA1.file(dest_filename).hexdigest
      tmpfile_digest = Digest::SHA1.file(tmpfile.path).hexdigest

      if existing_file_digest != tmpfile_digest
        return error_response(409, "Gem already exists, you must delete the existing version first.")
      else
        return [200, "Ignoring upload, you uploaded the same thing previously."]
      end
    end

    File.open(dest_filename, "wb") do |f|
      while blk = tmpfile.read(65536)
        f << blk
      end
    end
    reindex
    redirect url("/")
  end

private

  def error_response(code, message)
    html = <<HTML
<html>
  <head><title>Error - #{code}</title></head>
  <body>
    <h1>Error - #{code}</h1>
    <p>#{message}</p>
  </body>
</html>
HTML
    [code, html]
  end

  def reindex
    Geminabox.fixup_bundler_rubygems!
    indexer.generate_index
  end

  def indexer
    Gem::Indexer.new(settings.data, :build_legacy => settings.build_legacy)
  end

  def file_path
    File.expand_path(File.join(settings.data, *request.path_info))
  end

  def load_gems
    %w(specs prerelease_specs).inject(GemVersionCollection.new){|gems, specs_file_type|
      specs_file_path = File.join(settings.data, "#{specs_file_type}.#{Gem.marshal_version}.gz")
      if File.exists?(specs_file_path)
        gems |= Geminabox::GemVersionCollection.new(Marshal.load(Gem.gunzip(Gem.read_binary(specs_file_path))))
      end
      gems
    }
  end

  def index_gems(gems)
    Set.new(gems.map{|gem| gem.name[0..0]})
  end

  helpers do
    def spec_for(gem_name, version)
      spec_file = File.join(settings.data, "quick", "Marshal.#{Gem.marshal_version}", "#{gem_name}-#{version}.gemspec.rz")
      Marshal.load(Gem.inflate(File.read(spec_file))) if File.exists? spec_file
    end
  end
end
