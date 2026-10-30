require "rails_helper"

RSpec.describe "Frontend", type: :request do
  let(:index_file) { Rails.root.join("tmp/spec_index.html") }

  before do
    File.write(index_file, "<div id=\"root\"></div>")
    stub_const("FrontendController::INDEX_FILE", index_file)
  end

  after { FileUtils.rm_f(index_file) }

  it "serves the React app for the root path" do
    get "/", headers: { "Accept" => "text/html" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<div id="root"></div>')
  end

  it "serves the React app for client-side routes so deep links work" do
    get "/employees/42", headers: { "Accept" => "text/html" }

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/html")
  end

  it "does not serve the React app for unknown API paths" do
    get "/api/unknown", headers: { "Accept" => "text/html" }

    expect(response).to have_http_status(:not_found)
    expect(response.body).not_to include('<div id="root"></div>')
  end

  it "returns 404 when the frontend has not been built" do
    FileUtils.rm_f(index_file)

    get "/", headers: { "Accept" => "text/html" }

    expect(response).to have_http_status(:not_found)
  end
end
