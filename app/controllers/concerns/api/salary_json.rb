module Api
  # JSON for money and salary revisions. Money goes out as a string with
  # 2 decimals so no precision is lost on the way to the browser.
  module SalaryJson
    private
      def money_json(amount, currency_code)
        { amount: format_money(amount), currency_code: currency_code }
      end

      def format_money(amount)
        ActiveSupport::NumberHelper.number_to_rounded(amount, precision: 2)
      end

      # A percentage as a string with 2 decimals, e.g. "10.00".
      def format_percent(value)
        ActiveSupport::NumberHelper.number_to_rounded(value, precision: 2)
      end

      def revision_json(revision)
        {
          id: revision.id,
          effective_on: revision.effective_on,
          amount: format_money(revision.amount),
          currency_code: revision.currency_code,
          reason: revision.reason,
          never_applied: revision.never_applied?
        }
      end
  end
end
