class Api::V1::BaseApiController < ApplicationController
  protect_from_forgery with: :null_session

  before_filter :set_default_response_format

  rescue_from Exception do |exception|
    Rails.logger.warn("[Unhandled API Exception] [#{exception.class.name}] #{exception.message}")
    Rails.logger.warn(exception.backtrace.join("\n"))
    render_error code: 500, message: "[#{exception.class.name}] #{exception.message}"
  end

  rescue_from 'Changeset::Error' do |exception|
    render_error code: 400, message: exception.message
  end

  rescue_from 'ActiveRecord::RecordNotFound' do |exception|
    render_error code: 404, message: exception.message
  end

  rescue_from 'ActionController::RoutingError' do |exception|
    render_error code: 404, message: exception.message
  end

  rescue_from 'ActionController::UnknownController' do |exception|
    render_error code: 404, message: exception.message
  end

  rescue_from 'ActiveRecord::RecordInvalid' do |exception|
    render_error code: 400, message: exception.message
  end

  rescue_from 'ActionController::ParameterMissing' do |exception|
    render_error code: 400, message: exception.message
  end

  rescue_from 'ActiveRecord::UnknownAttributeError' do |exception|
    render_error code: 400, message: exception.message
  end

  # following this pattern: https://gist.github.com/Sujimichi/2349565
  def raise_not_found!
    raise ActionController::RoutingError.new("No route matches #{request.env['REQUEST_METHOD']} /api/#{params[:unmatched_route]}")
  end

  private

  def require_api_auth_token
    authenticate_or_request_with_http_token do |token, options|
      api_auth_tokens.include?(token)
    end
  end

  def api_auth_tokens
    @api_auth_tokens ||= Figaro.env.api_auth_tokens.split(',').map(&:to_s).map(&:strip)
  end

  def set_default_response_format
    request.format = :json unless [:geojson, :csv].include?(request.format.to_sym)
  end

  def render_error(code: 500, message: '', errors: {})
    error_hash = {}
    error_hash[:message] = message if message.present?
    error_hash[:errors] = errors if errors.keys.length > 0
    render json: error_hash, status: code
  end
end
