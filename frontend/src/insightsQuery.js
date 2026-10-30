// Dashboard month, filters and grouping live in the URL, like the employee list.

const KEYS = ['month', 'country_id', 'department', 'job_title']

export function parseInsightsQuery(search) {
  const params = new URLSearchParams(search)
  const query = Object.fromEntries(KEYS.map((key) => [key, params.get(key) ?? '']))
  return { ...query, group_by: params.get('group_by') === 'department' ? 'department' : 'country' }
}

export function insightsQueryString(query) {
  const params = new URLSearchParams()
  for (const key of KEYS) {
    if (query[key]) params.set(key, query[key])
  }
  if (query.group_by === 'department') params.set('group_by', 'department')
  const search = params.toString()
  return search ? `?${search}` : ''
}
