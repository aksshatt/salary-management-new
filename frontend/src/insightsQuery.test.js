import { describe, expect, it } from 'vitest'
import { insightsQueryString, parseInsightsQuery } from './insightsQuery.js'

describe('parseInsightsQuery', () => {
  it('defaults to no month (the API picks last month), no filters and cost by country', () => {
    expect(parseInsightsQuery('')).toEqual({ month: '', country_id: '', department: '', job_title: '', group_by: 'country' })
  })

  it('reads the month, filters and a department grouping', () => {
    expect(parseInsightsQuery('?month=2026-09&department=Sales&group_by=department')).toMatchObject({
      month: '2026-09',
      department: 'Sales',
      group_by: 'department',
    })
  })
})

describe('insightsQueryString', () => {
  it('leaves out empty values and the default grouping, and round-trips', () => {
    const query = { month: '2026-09', country_id: '', department: 'Sales', job_title: '', group_by: 'country' }

    expect(insightsQueryString(query)).toBe('?month=2026-09&department=Sales')
    expect(parseInsightsQuery(insightsQueryString({ ...query, group_by: 'department' }))).toEqual({ ...query, group_by: 'department' })
  })
})
