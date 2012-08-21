require 'rubygems'
require 'digest/md5'
require 'builder'
require 'sinatra/base'
require 'rubygems/builder'
require 'rubygems/indexer'
require 'hostess'
require 'geminabox/version'
require 'rss/atom'
require 'tempfile'

class Geminabox < Sinatra::Base
  enable :static, :methodoverride

  set :public_folder, File.join(File.dirname(__FILE__), *%w[.. public])
  set :data, File.join(File.dirname(__FILE__), *%w[.. data])
  set :build_legacy, false
  set :incremental_updates, false
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
  autoload :DiskCache, "geminabox/disk_cache"

  before do
    headers 'X-Powered-By' => "geminabox #{GeminaboxVersion}"
  end

  get '/' do
    @gems = load_gems
    @index_gems = index_gems(@gems)
    erb :index
  end

  get '/atom.xml' do
    @gems = load_gems
    erb :atom, :layout => false
  end

  get '/api/v1/dependencies' do
    query_gems = params[:gems].split(',').sort
    cache_key = query_gems.join(',')
    disk_cache.cache(cache_key) do
      deps = load_gems.gems.select {|gem| query_gems.include?(gem.name) }.map do |gem|
        spec = spec_for(gem.name, gem.number)
        {
          :name => gem.name,
          :number => gem.number.version,
          :platform => gem.platform,
          :dependencies => spec.dependencies.select {|dep| dep.type == :runtime}.map {|dep| [dep.name, dep.requirement.to_s] }
        }
      end
      Marshal.dump(deps)
    end
  end

  get '/upload' do
    erb :upload
  end

  get '/reindex' do
    reindex(:force_rebuild)
    redirect url("/")
  end

  get '/gems/:gemname' do
    gems = Hash[load_gems.by_name]
    @gem = gems[params[:gemname]]
    halt 404 unless @gem
    erb :gem
  end

  delete '/gems/*.gem' do
    File.delete file_path if File.exists? file_path
    reindex(:force_rebuild)
    redirect url("/")
  end

  post '/upload' do
    if File.exists? Geminabox.data
      error_response( 500, "Please ensure #{File.expand_path(Geminabox.data)} is a directory." ) unless File.directory? Geminabox.data
      error_response( 500, "Please ensure #{File.expand_path(Geminabox.data)} is writable by the geminabox web server." ) unless File.writable? Geminabox.data
    else
      begin
        FileUtils.mkdir_p(settings.data)
      rescue Errno::EACCES, Errno::ENOENT, RuntimeError => e
        error_response( 500, "Could not create #{File.expand_path(Geminabox.data)}.\n#{e}\n#{e.message}" )
      end
    end

    unless params[:file] && (tmpfile = params[:file][:tempfile]) && (name = params[:file][:filename])
      @error = "No file selected"
      halt [400, erb(:upload)]
    end

    FileUtils.mkdir_p(File.join(settings.data, "gems"))

    tmpfile.binmode

    gem_name = File.basename(name)
    dest_filename = File.join(settings.data, "gems", gem_name)

    if Geminabox.disallow_replace? and File.exist?(dest_filename)
      existing_file_digest = Digest::SHA1.file(dest_filename).hexdigest
      tmpfile_digest = Digest::SHA1.file(tmpfile.path).hexdigest

      if existing_file_digest != tmpfile_digest
        error_response(409, "Updating an existing gem is not permitted.\nYou should either delete the existing version, or change your version number.")
      else
        error_response(200, "Ignoring upload, you uploaded the same thing previously.")
      end
    end
    
    atomic_write(dest_filename) do |f|
      while blk = tmpfile.read(65536)
        f << blk
      end
    end
    reindex
    
    if api_request?
      "Gem #{gem_name} received and indexed."
    else
      redirect url("/")
    end
  end

private

  def api_request?
    request.accept.first == "text/plain"
  end

  def error_response(code, message)
    halt [code, message] if api_request?
    html = <<HTML
<html>
  <head><title>Error - #{code}</title></head>
  <body>
    <h1>Error - #{code}</h1>
    <p>#{message}</p>
  </body>
</html>
HTML
    halt [code, html]
  end

  def reindex(force_rebuild = false)
    Geminabox.fixup_bundler_rubygems!
    force_rebuild = true unless settings.incremental_updates
    if force_rebuild
      indexer.generate_index
    else
      begin
        indexer.update_index
      rescue => e
        puts "#{e.class}:#{e.message}"
        puts e.backtrace.join("\n")
        reindex(:force_rebuild)
      end
    end
    disk_cache.flush
  end

  def indexer
    Gem::Indexer.new(settings.data, :build_legacy => settings.build_legacy)
  end

  def file_path
    File.expand_path(File.join(settings.data, *request.path_info))
  end

  def disk_cache
    @disk_cache = Geminabox::DiskCache.new(File.join(settings.data, "_cache"))
  end

  def load_gems
    @loaded_gems ||=
      %w(specs prerelease_specs).inject(GemVersionCollection.new){|gems, specs_file_type|
        specs_file_path = File.join(settings.data, "#{specs_file_type}.#{Gem.marshal_version}.gz")
        if File.exists?(specs_file_path)
          gems |= Geminabox::GemVersionCollection.new(Marshal.load(Gem.gunzip(Gem.read_binary(specs_file_path))))
        end
        gems
      }
  end

  def index_gems(gems)
    Set.new(gems.map{|gem| gem.name[0..0].downcase})
  end

  # based on http://as.rubyonrails.org/classes/File.html
  def atomic_write(file_name)
    temp_dir = File.join(settings.data, "_temp")
    FileUtils.mkdir_p(temp_dir)
    temp_file = Tempfile.new("." + File.basename(file_name), temp_dir)
    yield temp_file
    temp_file.close
    File.rename(temp_file.path, file_name)
  end
  
  helpers do
    def spec_for(gem_name, version)
      spec_file = File.join(settings.data, "quick", "Marshal.#{Gem.marshal_version}", "#{gem_name}-#{version}.gemspec.rz")
      Marshal.load(Gem.inflate(File.read(spec_file))) if File.exists? spec_file
    end
  end
end
