class ApplicationController < ActionController::Base

  rescue_from Exception, :with => :show_error

  def show_error(e)
    raise if !request.xhr? || !Rails.env.development?

    render :json => { :message => e.message, :log => e.backtrace },
      :status => :unprocessable_entity
  end
end
