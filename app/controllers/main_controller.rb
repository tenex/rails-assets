class MainController < ApplicationController
  def home
  end

  def dependencies
    gem_names = params[:gems].to_s
      .split(",")
      .select {|e| e.start_with?(GEM_PREFIX) }
      .map { |e| e.gsub(GEM_PREFIX, "") }
    
    gems = gem_names.flat_map do |name|

      Build::Converter.run!(name) if Component.needs_build?(name)

      component = Component.where(name: name).first

      if component && component.built?
        component.versions.built.map do |v|
          {
            name:         name,
            platform:     "ruby",
            number:       v.string,
            dependencies: v.dependencies.to_a.map {|n,v| ["#{GEM_PREFIX}#{n}", v] }
          }
        end
      else
        []
      end
    end

    params[:json] ? render(json: gems) : render(text: Marshal.dump(gems))
  end

end
