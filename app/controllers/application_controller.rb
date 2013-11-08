class ApplicationController < ActionController::Base

  rescue_from Exception, :with => :show_error

  def show_error(e)

    Rails.logger.error(e)

    raise if !request.xhr? || !Rails.env.development?

    if Rails.env.development?
      render :json => { :message => e.message, :log => e.backtrace.join("\n") },
        :status => :unprocessable_entity
    else
      render :json => { :message => e.message }, :status => :unprocessable_entity
    end
  end

end
