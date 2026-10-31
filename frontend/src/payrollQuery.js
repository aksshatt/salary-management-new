// Payroll month, search and page live in the URL, like the employee list.

export function parsePayrollQuery(search) {
  const params = new URLSearchParams(search)
  const page = Number(params.get('page'))
  return {
    month: params.get('month') ?? '',
    q: params.get('q') ?? '',
    page: Number.isInteger(page) && page > 0 ? page : 1,
  }
}

export function payrollQueryString({ month, q, page }) {
  const params = new URLSearchParams()
  if (month) params.set('month', month)
  if (q) params.set('q', q)
  if (page > 1) params.set('page', page)
  const search = params.toString()
  return search ? `?${search}` : ''
}
