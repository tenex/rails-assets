if Rails.env.development?
  class NgTemplatesController < ApplicationController
    def show
      render params[:id]
    end
  end
end
