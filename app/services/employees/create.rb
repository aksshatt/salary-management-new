module Employees
  # Adds an employee together with their initial salary, so no employee ever
  # exists without one.
  class Create
    Result = Data.define(:employee, :errors) do
      def success? = errors.empty?
    end

    def initialize(attributes, initial_salary:)
      @attributes = attributes
      @initial_salary = initial_salary
    end

    def call
      employee = Employee.new(@attributes)
      revision = SalaryRevision.new(employee:, effective_on: employee.joined_on, amount: @initial_salary, reason: "initial")
      errors = validation_errors(employee, revision)
      return Result.new(employee:, errors:) if errors.any?

      ActiveRecord::Base.transaction do
        employee.save!
        revision.save!
      end
      Result.new(employee:, errors: {})
    end

    private
      # Check both records first so HR sees every problem at once.
      def validation_errors(employee, revision)
        employee.validate
        revision.validate
        errors = employee.errors.to_hash
        errors[:initial_salary] = revision.errors[:amount] if revision.errors[:amount].any?
        errors
      end
  end
end
