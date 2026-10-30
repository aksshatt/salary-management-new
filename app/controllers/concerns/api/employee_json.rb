module Api
  # Employee fields shared by the employee and termination endpoints. The bank
  # account number is always masked; only the payroll export shows it in full.
  module EmployeeJson
    private
      def employee_json(employee)
        {
          id: employee.id,
          code: employee.code,
          name: employee.name,
          email: employee.email,
          country: employee.country.slice(:id, :name, :currency_code),
          department: employee.department,
          job_title: employee.job_title,
          joined_on: employee.joined_on,
          terminated_on: employee.terminated_on,
          status: employee.status,
          bank_account: employee.masked_bank_account
        }
      end
  end
end
