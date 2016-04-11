if Rails.env.development?
  class NgTemplatesController < ApplicationController
    def show
      render params[:id], layout: false
    end
  end
end
