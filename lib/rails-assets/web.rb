require "sinatra/base"
require "slim"
require "redcarpet"
require "raven"

require "rails-assets"
require "rails-assets/serve"

require "faye"
require 'sprockets'
require 'sprockets-helpers'
require 'autoprefixer-rails/compiler'

if ENV["RAVEN_DSN"]
  Raven.configure do |config|
    config.dsn = ENV["RAVEN_DSN"]
  end
end

module RailsAssets
  class Web < Sinatra::Base
    set :root, File.join(File.dirname(__FILE__), ['..', '..'])
    set :sprockets, Sprockets::Environment.new(root)

    configure do
      sprockets.append_path File.join(root, 'assets', 'stylesheets')
      sprockets.append_path File.join(root, 'assets', 'javascripts')
      sprockets.append_path File.join(root, 'assets', 'images')

      sprockets.register_postprocessor 'text/css', :autoprefixer do |context, css|
        autoprefixer = AutoprefixerRails::Compiler.new(nil)
        autoprefixer.compile(css)
      end

      Sprockets::Helpers.configure do |config|
        config.environment = sprockets
        config.prefix      = '/assets'
        config.digest      = false
        config.public_path = public_folder
        config.debug       = true if development?
      end
    end

    helpers do
      include Sprockets::Helpers
    end

    use Raven::Rack

    use Faye::RackAdapter, mount: '/faye', timeout: 25

    use Serve

    get '/' do
      "Comming soon..."
    end

    get '/home' do
      slim :index
    end

    get '/index.json' do
      gems = index.all.map do |gem_name|
        component = Component.new(gem_name)
        versions = index.versions(gem_name)
        component.version = versions.first
        {
          :name => component.name,
          :versions => versions,
          :description => Tilt[:markdown].new { component.description }.render,
          :homepage => component.homepage,
          :dependencies => index.dependencies(gem_name, versions.first)
        }
      end

      json gems
    end

    post '/convert.json' do
      ps = params.empty? ? JSON.parse(request.body.read) : params
      component = Component.new(ps["pkg"].to_s.strip)

      io = StringIO.new

      if !params["force"] && index.exists?(component)
        halt 302
      else
        begin
          if c = Convert.new(component).convert!(:io => io, :force => params["force"])
            json 201, :name => c.name,
                      :version => c.version,
                      :gem => c.gem_name
          else
            halt 422
          end
        rescue BuildError, Exception => ex
          Raven.capture_exception(ex)
          io.puts ex.message
          io.puts ex.backtrace.take(5).first.gsub(File.dirname(File.dirname(__FILE__)), "")
          json 422, :error => ex.message, :log => io.string
        end
      end
    end

    get "/api/v1/dependencies" do
      gems = params["gems"].to_s
        .split(",")
        .select {|e| e.start_with?(GEM_PREFIX) }
        .flat_map do |name|
        vs = index.versions(name)

        if vs.empty?
          component = Component.new(name)
          if Convert.new(component).convert!
            vs = index.versions(name)
          end
        end

        vs.map do |v|
          {
            :name => name,
            :platform => "ruby",
            :number => v,
            :dependencies => index.dependencies(name, v).to_a
          }
        end
      end

      params["json"] ? json(gems) : Marshal.dump(gems)
    end


    def index
      @index ||= Index.new
    end

    def json(*args)
      status, data = args.size > 1 ? [args.first, args.last] : [200, args.first]

      content_type :json
      resp = JSON.dump(data)
      if status >= 400
        halt status, resp
      else
        resp
      end
    end
  end
end

