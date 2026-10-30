// The edit form never shows the full bank account number, so an empty field
// means "keep the current one" and is left out of the update.
export function employeeUpdatePayload(values) {
  const { bank_account_number, ...rest } = values
  return { employee: bank_account_number ? values : rest }
}
