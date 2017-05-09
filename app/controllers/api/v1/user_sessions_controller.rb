# https://github.com/jimjeffers/rails-devise-cors-jwt-example/blob/master/app/controllers/users/sessions_controller.rb

class Api::V1::UserSessionsController < Devise::SessionsController
  include JwtAuthToken

  skip_before_action :verify_authenticity_token

  # Only reply with JSON (not HTML)
  before_filter do
    request.format = :json
  end

  def create
    user = User.find_for_database_authentication(email: auth_params[:email])
    if user && user.valid_password?(auth_params[:password])
      render json: payload(user)
    else
      render json: { errors: ['Invalid Username/Password'] }, status: :unauthorized
    end
  end

    # DELETE /api/v1/users/session
  def destroy
    raise 'TODO: implement this'
  end

  private

  def payload(user)
    return nil unless user and user.id
    {
      token: JwtAuthToken.issue_token({user_id: user.id}),
      user: {
        id: user.id,
        email: user.email
      }
    }
  end

    def auth_params
      params.permit(:email, :password)
    end

    def resource
      @user ||= User.new
    end

    def devise_mapping
      @devise_mapping ||= Devise.mappings[:api_v1_user]
    end

end
