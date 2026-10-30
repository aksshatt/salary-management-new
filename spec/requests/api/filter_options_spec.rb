require "rails_helper"

RSpec.describe "API filter options", type: :request do
  it "returns 401 when not logged in" do
    get "/api/filter_options"

    expect(response).to have_http_status(:unauthorized)
  end

  it "lists countries, and the departments and job titles in use, sorted and without duplicates" do
    india = create(:country, name: "India", currency_code: "INR")
    brazil = create(:country, name: "Brazil", currency_code: "BRL")
    create(:employee, country: india, department: "Sales", job_title: "Manager")
    create(:employee, country: india, department: "Engineering", job_title: "Engineer")
    create(:employee, country: india, department: "Sales", job_title: "Engineer")
    log_in(create(:user))

    get "/api/filter_options"

    expect(response.parsed_body).to eq(
      "countries" => [
        { "id" => brazil.id, "name" => "Brazil", "currency_code" => "BRL" },
        { "id" => india.id, "name" => "India", "currency_code" => "INR" }
      ],
      "departments" => [ "Engineering", "Sales" ],
      "job_titles" => [ "Engineer", "Manager" ]
    )
  end
end
