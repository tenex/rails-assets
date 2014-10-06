class ApplicationController < ActionController::Base

  rescue_from Exception, :with => :show_error

  def cache_buster
    response.headers["Cache-Control"] =
      "no-cache, no-store, max-age=0, must-revalidate"

    response.headers["Pragma"] = "no-cache"

    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

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
