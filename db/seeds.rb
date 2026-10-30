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
  country_ids = Country.order(:name).pluck(:id)

  50.times do |i|
    department = roles.keys.sample(random: random)
    joined_on = Date.new(2020, 1, 1) + random.rand(2000)
    Employee.create!(
      name: "#{first_names.sample(random: random)} #{last_names.sample(random: random)}",
      email: "employee#{i + 1}@acme.test",
      country_id: country_ids.sample(random: random),
      department: department,
      job_title: roles[department].sample(random: random),
      joined_on: joined_on,
      terminated_on: (joined_on + 400 + random.rand(400) if random.rand < 0.15),
      bank_account_number: Array.new(12) { random.rand(10) }.join
    )
  end
end
puts "Employees: #{Employee.count}"
