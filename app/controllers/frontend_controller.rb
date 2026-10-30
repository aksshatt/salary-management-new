# Serves the built React app (copied into public/ at build time) for any
# non-API page route, so client-side routes and deep links work.
class FrontendController < ApplicationController
  INDEX_FILE = Rails.public_path.join("index.html")

  def show
    if File.exist?(INDEX_FILE)
      send_file INDEX_FILE, type: "text/html", disposition: "inline"
    else
      head :not_found
    end
  end
end
