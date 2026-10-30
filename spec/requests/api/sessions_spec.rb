require "rails_helper"

RSpec.describe "API session", type: :request do
  let!(:user) { create(:user, email_address: "hr@acme.test", password: "correct-horse-battery") }

  describe "GET /api/session" do
    it "returns 401 when not logged in" do
      get "/api/session"

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to eq("Not logged in")
    end

    it "returns the current user and a CSRF token when logged in" do
      log_in(user)
      get "/api/session"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["user"]).to eq("email_address" => "hr@acme.test")
      expect(response.parsed_body["csrf_token"]).to be_present
    end
  end

  describe "POST /api/session" do
    it "logs in with the correct email and password" do
      log_in(user)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["user"]).to eq("email_address" => "hr@acme.test")
      expect(user.sessions.count).to eq(1)
    end

    it "returns a CSRF token that works for the next write" do
      log_in(user)
      delete "/api/session", headers: { "X-CSRF-Token" => response.parsed_body["csrf_token"] }

      expect(response).to have_http_status(:no_content)
    end

    it "rejects a wrong password" do
      log_in(user, password: "wrong")

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to eq("Invalid email or password")
      expect(Session.count).to eq(0)
    end

    it "gives an unknown email the same response as a wrong password" do
      post "/api/session", params: { email_address: "nobody@acme.test", password: "wrong" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to eq("Invalid email or password")
    end

    it "accepts the email in any case and with surrounding spaces" do
      post "/api/session", params: { email_address: " HR@Acme.test ", password: "correct-horse-battery" }, as: :json

      expect(response).to have_http_status(:created)
    end

    it "blocks the 11th attempt within 3 minutes" do
      freeze_time do
        10.times { log_in(user, password: "wrong") }
        log_in(user)

        expect(response).to have_http_status(:too_many_requests)
        expect(response.parsed_body["error"]).to eq("Too many login attempts. Try again in a few minutes.")
      end
    end

    it "allows attempts again after the 3-minute window" do
      freeze_time do
        10.times { log_in(user, password: "wrong") }
        travel 3.minutes + 1.second
        log_in(user)

        expect(response).to have_http_status(:created)
      end
    end

    it "sets an httponly, SameSite=Lax session cookie" do
      log_in(user)

      expect(Array(response.headers["Set-Cookie"])).to include(a_string_matching(/\Asession_id=.*httponly; samesite=lax/i))
    end
  end

  describe "DELETE /api/session" do
    it "logs out, deletes the session and rejects the old cookie" do
      log_in(user)
      delete "/api/session", headers: csrf_headers

      expect(response).to have_http_status(:no_content)
      expect(Session.count).to eq(0)

      get "/api/session"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "CSRF protection" do
    it "rejects a logout without a CSRF token" do
      log_in(user)
      delete "/api/session"

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]).to eq("Invalid CSRF token. Reload the page and try again.")
      expect(Session.count).to eq(1)
    end

    it "rejects a logout with a forged CSRF token" do
      log_in(user)
      delete "/api/session", headers: { "X-CSRF-Token" => "forged" }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
