// Turns an audit event's changes ({ field: [old, new] }) into readable lines.
// Internal ids and the generated employee code are left out.

// What each audited record type is called in the UI.
export const TYPE_LABELS = {
  Employee: 'Employee',
  SalaryRevision: 'Salary revision',
  PayrollEntry: 'Payroll adjustment',
  PayrollRun: 'Payroll run',
  Country: 'Tax rate',
  ExchangeRate: 'Exchange rate',
}

const HIDDEN = /(_id|^code)$/

function label(field) {
  const words = field.replaceAll('_', ' ')
  return words.charAt(0).toUpperCase() + words.slice(1)
}

const show = (value) => (value === null || value === '' ? '—' : String(value))

export function describeChanges(changes) {
  return Object.entries(changes)
    .filter(([field]) => !HIDDEN.test(field))
    .map(([field, [before, after]]) => `${label(field)}: ${show(before)} → ${show(after)}`)
}
