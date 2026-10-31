import { describe, expect, it } from 'vitest'
import { employeeExportUrl, employeeQueryString, parseEmployeeQuery } from './employeeQuery.js'

describe('parseEmployeeQuery', () => {
  it('defaults to no filters on page 1', () => {
    expect(parseEmployeeQuery('')).toEqual({
      q: '',
      country_id: '',
      department: '',
      job_title: '',
      status: '',
      page: 1,
    })
  })

  it('reads the search text and filters', () => {
    expect(parseEmployeeQuery('?q=nair&country_id=3&department=Sales&job_title=Account+Manager&status=active')).toMatchObject({
      q: 'nair',
      country_id: '3',
      department: 'Sales',
      job_title: 'Account Manager',
      status: 'active',
    })
  })

  it('reads a valid page number and falls back to 1 otherwise', () => {
    expect(parseEmployeeQuery('?page=3').page).toBe(3)
    for (const page of ['0', '-2', 'abc', '2.5']) {
      expect(parseEmployeeQuery(`?page=${page}`).page).toBe(1)
    }
  })
})

describe('employeeQueryString', () => {
  it('leaves out empty filters and page 1', () => {
    expect(employeeQueryString({ q: '', country_id: '', department: 'Sales', job_title: '', status: '', page: 1 })).toBe(
      '?department=Sales',
    )
  })

  it('includes later pages, and round-trips through parseEmployeeQuery', () => {
    const query = { q: 'nair', country_id: '3', department: '', job_title: 'Account Manager', status: 'active', page: 4 }

    expect(parseEmployeeQuery(employeeQueryString(query))).toEqual(query)
  })
})

describe('employeeExportUrl', () => {
  it('exports with the current search and filters, but every page', () => {
    const query = { q: 'nair', country_id: '3', department: '', job_title: '', status: 'active', page: 4 }

    expect(employeeExportUrl(query)).toBe('/api/employees/export.csv?q=nair&country_id=3&status=active')
    expect(employeeExportUrl({ ...query, q: '', country_id: '', status: '' })).toBe('/api/employees/export.csv')
  })
})
