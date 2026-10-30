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

countries = {
  "Brazil" => "BRL",
  "Germany" => "EUR",
  "India" => "INR",
  "United Kingdom" => "GBP",
  "United States" => "USD"
}

countries.each do |name, currency_code|
  Country.find_or_create_by!(name: name) { |country| country.currency_code = currency_code }
end
puts "Countries ready: #{Country.count}"

# A small, fixed sample so the app isn't empty in development. The full
# 10,000-employee seed comes once salaries exist.
if Employee.none?
  random = Random.new(42)
  first_names = %w[Aarav Ana Ben Chloe Diego Emma Felix Hannah Isha Jonas Lucas Maya Noah Olivia Priya Rahul Sofia Tom]
  last_names = %w[Almeida Becker Brown Costa Fischer Garcia Gupta Iyer Johnson Mehta Miller Nair Schmidt Silva Smith Taylor]
  roles = {
    "Engineering" => [ "Software Engineer", "Senior Software Engineer", "Engineering Manager" ],
    "Sales" => [ "Account Executive", "Sales Manager" ],
    "Finance" => [ "Accountant", "Finance Manager" ],
    "People" => [ "HR Generalist", "Recruiter" ]
  }
  countries = Country.order(:name).to_a
  # Rough starting salaries in each local currency, so amounts look realistic.
  base_salary = { "BRL" => 90_000, "EUR" => 55_000, "INR" => 1_200_000, "GBP" => 45_000, "USD" => 80_000 }

  50.times do |i|
    department = roles.keys.sample(random: random)
    joined_on = Date.new(2020, 1, 1) + random.rand(2000)
    country = countries.sample(random: random)
    employee = Employee.create!(
      name: "#{first_names.sample(random: random)} #{last_names.sample(random: random)}",
      email: "employee#{i + 1}@acme.test",
      country: country,
      department: department,
      job_title: roles[department].sample(random: random),
      joined_on: joined_on,
      terminated_on: (joined_on + 400 + random.rand(400) if random.rand < 0.15),
      bank_account_number: Array.new(12) { random.rand(10) }.join
    )

    amount = (base_salary.fetch(country.currency_code) * (0.8 + random.rand * 0.6)).round(-2)
    employee.salary_revisions.create!(effective_on: joined_on, amount: amount, reason: "initial")
    effective_on = joined_on
    random.rand(4).times do
      effective_on += 300 + random.rand(200)
      break if employee.terminated_on && effective_on > employee.terminated_on

      amount = (amount * (1.03 + random.rand * 0.12)).round(-2)
      employee.salary_revisions.create!(effective_on: effective_on, amount: amount,
        reason: random.rand < 0.2 ? "promotion" : "increment")
    end
  end
end
puts "Employees: #{Employee.count}"
