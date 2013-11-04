class ErrorsController < ActionController::Base

  # Because we don't inherit from ApplicationController
  layout 'error'

  # You can use these method in views
  helper_method :status_code, :status_name, :error_message

  # You can edit format.json for proper API response format.
  def show
    custom_template = template_exists?(status_code, 'errors')

    respond_to do |format|
      format.html { render action: custom_template ? status_code.to_s : 'show' }

      if Rails.env.production?
        format.json { render json: { status: status_code, message: error_message }, status: status_code }
      else
        format.json { render json: { status: status_code, message: error_message, log: error_trace }, status: status_code }
      end
    end
  end

  protected

  def status_code
    (request.path.match(/\d{3}/) || ['500'])[0].to_i
  end

  def status_name
    Rack::Utils::HTTP_STATUS_CODES.fetch(status_code, "Internal Server Error")
  end

  def error_message
    if status_code != 500 && exception
      exception.message
    else
      "Our administrator has been notified about this event."
    end
  end

  def error_trace
    if status_code != 500 && exception
      exception.backtrace
    end
  end

  def exception
    env['action_dispatch.exception']
  end
end
