require "caxlsx"

module Payroll
  # The month's payroll as an Excel file for paying people. Reads the stored
  # entries only (never recalculates). The only place the full bank account
  # number appears.
  class Exporter
    HEADERS = [ "Code", "Name", "Bank account", "Currency", "Days worked", "Days in month", "Annual salary",
      "Monthly gross", "Bonus", "Deduction", "Note", "Tax rate %", "Tax", "Net" ].freeze
    TEXT_COLUMNS = [ "Code", "Name", "Bank account", "Currency", "Note" ].freeze
    MONEY_COLUMNS = [ "Annual salary", "Monthly gross", "Bonus", "Deduction", "Tax", "Net" ].freeze

    def initialize(run)
      @run = run
    end

    def to_xlsx
      package = Axlsx::Package.new
      money = package.workbook.styles.add_style(format_code: "#,##0.00")
      styles = HEADERS.map { |header| money if MONEY_COLUMNS.include?(header) }
      # Codes and bank account numbers are text: a digits-only account number
      # would otherwise become a number and lose its leading zeros.
      types = HEADERS.map { |header| :string if TEXT_COLUMNS.include?(header) }
      package.workbook.add_worksheet(name: "Payroll #{@run.month.strftime('%Y-%m')}") do |sheet|
        sheet.add_row HEADERS
        # caxlsx escapes text starting with "=" so it is never run as a formula (see spec).
        entries.each { |entry| sheet.add_row row(entry), style: styles, types: }
        sheet.add_row Array.new(HEADERS.size)
        totals.each { |total| sheet.add_row total_row(total), style: styles }
      end
      package.to_stream.read
    end

    private
      def entries
        @run.payroll_entries.joins(:employee).includes(:employee).order(:currency_code, "employees.name", "employees.id")
      end

      # One total per currency: amounts in different currencies are never added.
      def totals
        @run.payroll_entries.group(:currency_code).order(:currency_code)
          .pluck(:currency_code, *%w[monthly_gross bonus deduction tax net].map { |column| Arel.sql("SUM(#{column})") })
      end

      def total_row((currency_code, gross, bonus, deduction, tax, net))
        [ nil, "Total #{currency_code}", nil, currency_code, nil, nil, nil, gross, bonus, deduction, nil, nil, tax, net ]
      end

      def row(entry)
        employee = entry.employee
        [
          employee.code, employee.name, employee.bank_account_number, entry.currency_code, entry.days_worked,
          entry.days_in_month, entry.annual_salary, entry.monthly_gross, entry.bonus, entry.deduction, entry.note,
          entry.tax_rate_percent, entry.tax, entry.net
        ]
      end
  end
end
