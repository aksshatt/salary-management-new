# The single HR login. Credentials come from the environment so no password
# lives in the code.
hr_email = ENV.fetch("HR_EMAIL", nil)
hr_password = ENV.fetch("HR_PASSWORD", nil)

if hr_email.present? && hr_password.present?
  User.find_or_initialize_by(email_address: hr_email).update!(password: hr_password)
  puts "HR user ready: #{hr_email}"
else
  puts "Skipping HR user: set HR_EMAIL and HR_PASSWORD"
end

# Approximate rates (units per 1 USD); HR keeps them up to date in the app.
{ "BRL" => "5.05", "CAD" => "1.37", "EUR" => "0.92", "GBP" => "0.79", "INR" => "83.25", "SGD" => "1.34", "USD" => "1" }.each do |currency_code, units|
  ExchangeRate.find_or_create_by!(currency_code:) { |rate| rate.units_per_usd = units }
end

# Currency and an approximate flat tax rate (%) per country. Real tax rules are
# out of scope; HR can edit the rate in the app.
countries = {
  "Brazil" => [ "BRL", "27.5" ],
  "Canada" => [ "CAD", "26" ],
  "Germany" => [ "EUR", "35" ],
  "India" => [ "INR", "20" ],
  "Singapore" => [ "SGD", "15" ],
  "United Kingdom" => [ "GBP", "30" ],
  "United States" => [ "USD", "25" ]
}

countries.each do |name, (currency_code, tax_rate_percent)|
  Country.find_or_create_by!(name: name) do |country|
    country.currency_code = currency_code
    country.tax_rate_percent = tax_rate_percent
  end
end
puts "Countries ready: #{Country.count}"

# Sample employees with salary histories (10,000 by default; set
# SEED_EMPLOYEES for fewer). Fixed random seed, so every run gives the same data
# for the same day.
if Employee.none?
  count = (ENV["SEED_EMPLOYEES"].presence || 10_000).to_i
  Employees::SampleData.new(count:, today: Date.current, seed: 42).call
end
puts "Employees: #{Employee.count}"
