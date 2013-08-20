class MainController < ApplicationController
  def list
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

    render json: gems
  end

  def convert
    component = Component.new(params[:pkg].to_s.strip)

    io = StringIO.new

    if !params[:force] && index.exists?(component)
      head :found
    else
      begin
        if c = Convert.new(component).convert!(:io => io, :force => params[:force])
          render json: {
            name:     c.name,
            version:  c.version,
            gem:      c.gem_name
          }
        else
          head :unprocessable_entity
        end
      rescue BuildError, Exception => ex
        Raven.capture_exception(ex)
        io.puts ex.message
        io.puts ex.backtrace.take(5).first.gsub(File.dirname(File.dirname(__FILE__)), "")
        render json: { error: ex.message, log: io.string }, status: :unprocessable_entity
      end
    end
  end

  def dependencies
    gems = params[:gems].to_s
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

    params[:json] ? render(json: gems) : Marshal.dump(gems)
  end


  protected

  def index
    @index ||= Index.new
  end
end
