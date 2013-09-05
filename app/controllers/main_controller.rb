class MainController < ApplicationController
  def list
    respond_to do |format|
      format.html {}
      format.json do
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
    end
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

        log = io.string

        render json: {
          message: discover_error_cause(log) || ex.message,
          log: log
        }, status: :unprocessable_entity
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

    params[:json] ? render(json: gems) : render(text: Marshal.dump(gems))
  end


  protected

  def index
    @index ||= Index.new
  end

  def discover_error_cause(log)
    if pkg = log[/INFO - \[stdout\] - \e\[31m(.+)\e\[39m not found/, 1]
      "Package #{pkg.strip} not found"
    else
      nil
    end
  end
end
