class ApplicationController < ActionController::Base
  before_action :log_access

  def respond_with_error(errors, status = :bad_request)
    render json: { errors: [*errors] }, status: status
  end

  def log_access
    f = ActionDispatch::Http::ParameterFilter.new(TemplateService::Application.config.filter_parameters)

    logger.info "[#{params[:controller]}] #{f.filter(params.except(:controller, :format)).inspect}"
  end
end
