import { describe, expect, it } from 'vitest'
import { formatChange, formatMoney, formatSalaryWithUsd } from './format.js'

describe('formatMoney', () => {
  it('formats an API money string with its currency symbol and 2 decimals', () => {
    expect(formatMoney({ amount: '1320000.50', currency_code: 'INR' })).toBe('₹1,320,000.50')
    expect(formatMoney({ amount: '55000.00', currency_code: 'EUR' })).toBe('€55,000.00')
  })

  it('shows a dash when there is no salary', () => {
    expect(formatMoney(null)).toBe('—')
  })
})

describe('formatSalaryWithUsd', () => {
  it('adds the USD value after a local salary', () => {
    expect(formatSalaryWithUsd({ amount: '1320000.50', currency_code: 'INR', usd: '15855.86' })).toBe(
      '₹1,320,000.50 (≈ $15,855.86)',
    )
  })

  it('shows just the amount for USD salaries or when there is no rate', () => {
    expect(formatSalaryWithUsd({ amount: '80000.00', currency_code: 'USD', usd: '80000.00' })).toBe('$80,000.00')
    expect(formatSalaryWithUsd({ amount: '1000.00', currency_code: 'INR', usd: null })).toBe('₹1,000.00')
  })
})

describe('formatChange', () => {
  it('shows a sign for rises and drops, and a dash when there is no comparison', () => {
    expect([formatChange('10.00'), formatChange('-1.50'), formatChange('0.00'), formatChange(null)]).toEqual([
      '+10.00%',
      '−1.50%',
      '0.00%',
      '—',
    ])
  })
})
