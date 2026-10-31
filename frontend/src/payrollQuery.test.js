import { describe, expect, it } from 'vitest'
import { parsePayrollQuery, payrollQueryString } from './payrollQuery.js'

describe('payroll query', () => {
  it('reads the month, search and page from the URL', () => {
    expect(parsePayrollQuery('')).toEqual({ month: '', q: '', page: 1 })
    expect(parsePayrollQuery('?month=2026-09&q=nair&page=3')).toEqual({ month: '2026-09', q: 'nair', page: 3 })
    expect(parsePayrollQuery('?page=abc').page).toBe(1)
  })

  it('writes them back, leaving out empty values and page 1', () => {
    expect(payrollQueryString({ month: '2026-09', q: '', page: 1 })).toBe('?month=2026-09')
    expect(payrollQueryString({ month: '2026-09', q: 'nair', page: 2 })).toBe('?month=2026-09&q=nair&page=2')
    expect(payrollQueryString({ month: '', q: '', page: 1 })).toBe('')
  })
})
