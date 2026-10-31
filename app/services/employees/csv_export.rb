require "csv"

module Employees
  # The employee list as CSV for HR, using the same search and filters as the
  # list. The bank account stays masked: only the payroll export shows it.
  class CsvExport
    HEADERS = [ "Code", "Name", "Email", "Country", "Department", "Job title", "Joined", "Last working day", "Status",
      "Annual salary", "Currency", "Annual salary (USD)", "Bank account" ].freeze

    # employees: an EmployeeSearch result (it already carries current salary and USD).
    def initialize(employees)
      @employees = employees
    end

    # Starts with a byte-order mark so Excel opens it as UTF-8.
    def to_csv
      CSV.generate("\uFEFF") do |csv|
        csv << HEADERS
        @employees.each { |employee| csv << row(employee) }
      end
    end

    private
      def row(employee)
        [
          employee.code, *[ employee.name, employee.email, employee.country.name, employee.department, employee.job_title ].map { |text| safe(text) },
          employee.joined_on, employee.terminated_on, employee.status,
          money(employee.current_salary_amount), employee.current_salary_currency, money(employee.current_salary_usd),
          employee.masked_bank_account
        ]
      end

      # Spreadsheets run cells starting with these as formulas (CSV injection);
      # a leading apostrophe makes them plain text.
      def safe(text)
        text.start_with?("=", "+", "-", "@", "\t", "\r") ? "'#{text}" : text
      end

      def money(amount)
        amount && ActiveSupport::NumberHelper.number_to_rounded(amount, precision: 2)
      end
  end
end
