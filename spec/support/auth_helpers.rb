module AuthHelpers
  def log_in(user, password: "correct-horse-battery")
    post "/api/session", params: { email_address: user.email_address, password: password }, as: :json
  end

  # CSRF protection is on in tests, so writes need the token the SPA would send.
  def csrf_headers
    get "/api/session"
    { "X-CSRF-Token" => response.parsed_body["csrf_token"] }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
  # The login rate limit counts per IP, and every spec uses the same IP.
  config.before(type: :request) { Api::SessionsController::RATE_LIMIT_STORE.clear }
end
