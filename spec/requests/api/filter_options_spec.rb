require "rails_helper"

RSpec.describe "API filter options", type: :request do
  it "returns 401 when not logged in" do
    get "/api/filter_options"

    expect(response).to have_http_status(:unauthorized)
  end

  it "lists only countries, departments and job titles that have employees, sorted and without duplicates" do
    india = create(:country, name: "India", currency_code: "INR")
    create(:country, name: "Brazil", currency_code: "BRL")
    create(:employee, country: india, department: "Sales", job_title: "Manager")
    create(:employee, country: india, department: "Engineering", job_title: "Engineer")
    create(:employee, country: india, department: "Sales", job_title: "Engineer")
    log_in(create(:user))

    get "/api/filter_options"

    expect(response.parsed_body).to eq(
      "countries" => [ { "id" => india.id, "name" => "India", "currency_code" => "INR" } ],
      "departments" => [ "Engineering", "Sales" ],
      "job_titles" => [ "Engineer", "Manager" ]
    )
  end

  describe "narrowed by the other filters" do
    let(:india) { create(:country, name: "India", currency_code: "INR") }
    let(:brazil) { create(:country, name: "Brazil", currency_code: "BRL") }

    before do
      create(:employee, country: india, department: "Sales", job_title: "Account Executive")
      create(:employee, country: india, department: "Engineering", job_title: "Engineer")
      create(:employee, country: brazil, department: "Finance", job_title: "Accountant")
      log_in(create(:user))
    end

    def options(params)
      get "/api/filter_options", params: params
      response.parsed_body
    end

    it "offers only the departments and job titles found in the chosen country" do
      result = options(country_id: india.id)

      expect(result["departments"]).to eq([ "Engineering", "Sales" ])
      expect(result["job_titles"]).to eq([ "Account Executive", "Engineer" ])
    end

    it "offers only the countries and job titles of the chosen department, while still listing every department" do
      result = options(department: "Finance")

      expect(result["countries"].map { |c| c["name"] }).to eq([ "Brazil" ])
      expect(result["job_titles"]).to eq([ "Accountant" ])
      expect(result["departments"]).to eq([ "Engineering", "Finance", "Sales" ])
    end

    it "narrows by status too, and ignores an unknown status" do
      create(:employee, country: brazil, department: "People", job_title: "Recruiter", joined_on: Date.current + 30)

      expect(options(status: "upcoming")["departments"]).to eq([ "People" ])
      expect(options(status: "delete_all")["departments"]).to eq(%w[Engineering Finance People Sales])
      expect(Employee.count).to eq(4)
    end

    it "runs the same number of queries however many employees there are" do
      few = count_queries { options(country_id: india.id) }
      create_list(:employee, 20, country: india)

      expect(count_queries { options(country_id: india.id) }).to eq(few)
    end
  end
end
