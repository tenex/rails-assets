if !Rails.configuration.x.inline_ng_templates
  class NgTemplatesController < ApplicationController
    def show
      render params[:id], layout: false
    end
  end
end
