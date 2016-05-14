class ApplicationController < ActionController::Base
  rescue_from ActionController::UnknownFormat, with: :handle_unknown_format

  def handle_unknown_format
    render nothing: true, status: 406
  end
end
