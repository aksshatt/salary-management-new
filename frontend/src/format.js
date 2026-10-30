// Display formatting only; all money maths happens in the API.
// A fixed locale keeps the output the same on every machine.
export function formatMoney(money) {
  if (!money) return '—'
  const { amount, currency_code } = money
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: currency_code }).format(amount)
}
