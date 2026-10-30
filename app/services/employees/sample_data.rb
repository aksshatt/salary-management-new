module Employees
  # Generates realistic sample employees with salary histories for the seed.
  # Rows go in with insert_all (fast at 10k), so this class sets every value
  # the model would otherwise fill in. Same seed + today => same data.
  class SampleData
    BATCH_SIZE = 1_000

    # Base role and its typical USD salary at the mid level.
    DEPARTMENTS = {
      "Engineering" => [ "Software Engineer", 95_000 ],
      "Sales" => [ "Account Executive", 70_000 ],
      "Finance" => [ "Accountant", 70_000 ],
      "People" => [ "HR Generalist", 60_000 ],
      "Marketing" => [ "Marketing Specialist", 65_000 ],
      "Operations" => [ "Operations Analyst", 60_000 ]
    }.freeze

    # Career ladder: title pattern, pay multiplier, how common it is.
    LEVELS = [
      [ "Junior %{role}", 0.7, 30 ], [ "%{role}", 1.0, 35 ], [ "Senior %{role}", 1.35, 22 ], [ "Lead %{role}", 1.6, 8 ],
      [ "%{dept} Manager", 1.8, 5 ]
    ].freeze

    # Rough pay level per country relative to the US, before currency conversion.
    COUNTRY_PAY = { "USD" => 1.0, "CAD" => 0.85, "GBP" => 0.75, "EUR" => 0.8, "SGD" => 0.8, "BRL" => 0.35, "INR" => 0.3 }.freeze

    FIRST_NAMES = %w[Aarav Ana Ben Chloe Diego Emma Felix Hannah Isha Jonas Lucas Maya Noah Olivia Priya Rahul Sofia Tom
      Wei Yuki Amara Carlos Elena Farah Gabriel Ingrid Jamal Kiran Lena Mateo Nina Omar Paula Ravi Sara Tariq Uma Victor Zoe].freeze
    LAST_NAMES = %w[Almeida Becker Brown Costa Fischer Garcia Gupta Iyer Johnson Mehta Miller Nair Schmidt Silva Smith Taylor
      Tan Lim Wong Chen Kumar Singh Rossi Dubois Martin Wilson Clark Lewis Walker Young Patel Shah Kaur Ortiz Lopez Moreau].freeze

    def initialize(count:, today:, seed: 42)
      @count = count
      @today = today
      @random = Random.new(seed)
      @countries = Country.order(:name).to_a
      @rates = ExchangeRate.pluck(:currency_code, :units_per_usd).to_h
    end

    def call
      (1..@count).each_slice(BATCH_SIZE) do |numbers|
        people = numbers.map { |number| person(number) }
        ids = Employee.insert_all!(people.map { |p| p[:employee] }, returning: %w[id]).rows.flatten
        SalaryRevision.insert_all!(ids.zip(people).flat_map { |id, p| revisions(id, p) })
      end
    end

    private
      def person(number)
        country = @countries.sample(random: @random)
        department, (role, base_usd) = DEPARTMENTS.to_a.sample(random: @random)
        title_pattern, level_pay = pick_level
        joined_on = pick_join_date
        {
          country:,
          annual_usd: base_usd * level_pay * COUNTRY_PAY.fetch(country.currency_code, 0.6) * (0.85 + @random.rand * 0.3),
          employee: {
            name: "#{FIRST_NAMES.sample(random: @random)} #{LAST_NAMES.sample(random: @random)}",
            email: format("employee%05d@acme.test", number), country_id: country.id,
            department:, job_title: format(title_pattern, role:, dept: department), joined_on:,
            terminated_on: pick_last_working_day(joined_on),
            bank_account_number: Array.new(12) { @random.rand(10) }.join, created_at: Time.current, updated_at: Time.current
          }
        }
      end

      # An initial salary, then a review roughly every year: mostly a 2-8% raise,
      # sometimes a 10-20% promotion, now and then a small correction. Reviews
      # run up to three months ahead (scheduled raises) and stop at the last
      # working day.
      def revisions(employee_id, person)
        currency = person[:country].currency_code
        amount = (person[:annual_usd] * @rates.fetch(currency)).round(-2)
        date = person[:employee][:joined_on]
        last_date = [ @today + 90, person[:employee][:terminated_on] ].compact.min
        rows = [ revision_row(employee_id, date, amount, currency, "initial") ]

        loop do
          date += 330 + @random.rand(70)
          break if date > last_date

          reason, factor = pick_review
          amount = (amount * factor).round(-2)
          rows << revision_row(employee_id, date, amount, currency, reason)
        end
        rows
      end

      def pick_review
        roll = @random.rand
        if roll < 0.04 then [ "correction", 0.98 + @random.rand * 0.04 ]
        elsif roll < 0.19 then [ "promotion", 1.10 + @random.rand * 0.10 ]
        else [ "increment", 1.02 + @random.rand * 0.06 ]
        end
      end

      def revision_row(employee_id, effective_on, amount, currency_code, reason)
        { employee_id:, effective_on:, amount:, currency_code:, reason:, created_at: Time.current, updated_at: Time.current }
      end

      # Since 2018, weighted towards recent years as the company grows;
      # about 2% join in the next two months.
      def pick_join_date
        return @today + 1 + @random.rand(60) if @random.rand < 0.02

        days = (@today - Date.new(2018, 1, 1)).to_i
        @today - (days * @random.rand**1.6).to_i
      end

      # About 12% have left within the last three years, most in the last year
      # so the 12-month trends have movement.
      def pick_last_working_day(joined_on)
        return if joined_on > @today || @random.rand >= 0.12

        window = @random.rand < 0.6 ? 1.year : 3.years
        earliest = [ joined_on + 30, @today - window ].max
        latest = @today - 1
        earliest + @random.rand((latest - earliest).to_i + 1) if earliest <= latest
      end

      def pick_level
        roll = @random.rand(LEVELS.sum { |level| level[2] })
        LEVELS.find { |level| (roll -= level[2]).negative? }.first(2)
      end
  end
end
