// Display formatting only; all money maths happens in the API.
// A fixed locale keeps the output the same on every machine.
export function formatMoney(money) {
  if (!money) return '—'
  const { amount, currency_code } = money
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: currency_code }).format(amount)
}

export function formatSalaryWithUsd(salary) {
  const local = formatMoney(salary)
  if (!salary?.usd || salary.currency_code === 'USD') return local
  return `${local} (≈ ${formatMoney({ amount: salary.usd, currency_code: 'USD' })})`
}

// "10.00" → "+10.00%", "-1.50" → "−1.50%" (true minus sign), null → "—".
export function formatChange(percent) {
  if (percent === null) return '—'
  if (percent.startsWith('-')) return `−${percent.slice(1)}%`
  return Number(percent) > 0 ? `+${percent}%` : `${percent}%`
}
