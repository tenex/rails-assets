require 'sinatra/base'

class Hostess < Sinatra::Base
  def initialize(app, path)
    @path = path
    super(app)
  end

  def serve
    send_file(File.expand_path(File.join(@path, *request.path_info)))
  end

  %w[/specs.4.8.gz
     /latest_specs.4.8.gz
     /prerelease_specs.4.8.gz
  ].each do |index|
    get index do
      content_type('application/x-gzip')
      serve
    end
  end

  %w[/quick/Marshal.4.8/*.gemspec.rz
     /yaml.Z
     /Marshal.4.8.Z
  ].each do |deflated_index|
    get deflated_index do
      content_type('application/x-deflate')
      serve
    end
  end

  %w[/yaml
     /Marshal.4.8
     /specs.4.8
     /latest_specs.4.8
     /prerelease_specs.4.8
  ].each do |old_index|
    get old_index do
      serve
    end
  end

  get "/gems/*.gem" do
    serve
  end
end
