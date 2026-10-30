module Api
  class SessionsController < BaseController
    # One process on Render, so an in-memory store is enough for login throttling.
    RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new

    allow_unauthenticated_access only: :create
    # There is no session to hijack before login; the SameSite cookie covers login CSRF.
    skip_forgery_protection only: :create
    rate_limit to: 10, within: 3.minutes, only: :create, store: RATE_LIMIT_STORE,
      with: -> { render json: { error: "Too many login attempts. Try again in a few minutes." }, status: :too_many_requests }

    def show
      render json: { user: user_json(Current.user), csrf_token: form_authenticity_token }
    end

    def create
      user = User.authenticate_by(params.permit(:email_address, :password).to_h.symbolize_keys)

      if user
        start_new_session_for(user)
        render json: { user: user_json(user), csrf_token: form_authenticity_token }, status: :created
      else
        render json: { error: "Invalid email or password" }, status: :unauthorized
      end
    end

    def destroy
      terminate_session
      head :no_content
    end

    private
      def user_json(user)
        { email_address: user.email_address }
      end
  end
end
