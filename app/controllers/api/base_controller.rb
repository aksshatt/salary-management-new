module Api
  class BaseController < ApplicationController
    include ActionController::Cookies
    include ActionController::RequestForgeryProtection
    include Authentication

    protect_from_forgery with: :exception

    rescue_from ActiveRecord::RecordNotFound do
      render json: { error: "Not found" }, status: :not_found
    end

    rescue_from ActionController::InvalidAuthenticityToken do
      render json: { error: "Invalid CSRF token. Reload the page and try again." }, status: :unprocessable_content
    end
  end
end
