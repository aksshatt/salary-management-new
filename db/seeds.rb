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
