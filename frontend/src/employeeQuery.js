// Employee list filters live in the URL so Back, Forward and shared links work.

const FILTERS = ['q', 'country_id', 'department', 'job_title', 'status']

export function parseEmployeeQuery(search) {
  const params = new URLSearchParams(search)
  const query = Object.fromEntries(FILTERS.map((key) => [key, params.get(key) ?? '']))
  const page = Number(params.get('page'))
  return { ...query, page: Number.isInteger(page) && page > 0 ? page : 1 }
}

export function employeeQueryString(query) {
  const params = new URLSearchParams()
  for (const key of FILTERS) {
    if (query[key]) params.set(key, query[key])
  }
  if (query.page > 1) params.set('page', query.page)
  const search = params.toString()
  return search ? `?${search}` : ''
}

// The CSV export takes the same filters but always covers every page.
export function employeeExportUrl(query) {
  return `/api/employees/export.csv${employeeQueryString({ ...query, page: 1 })}`
}
