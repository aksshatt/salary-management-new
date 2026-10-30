import { describe, expect, it } from 'vitest'
import { formatMoney } from './format.js'

describe('formatMoney', () => {
  it('formats an API money string with its currency symbol and 2 decimals', () => {
    expect(formatMoney({ amount: '1320000.50', currency_code: 'INR' })).toBe('₹1,320,000.50')
    expect(formatMoney({ amount: '55000.00', currency_code: 'EUR' })).toBe('€55,000.00')
  })

  it('shows a dash when there is no salary', () => {
    expect(formatMoney(null)).toBe('—')
  })
})
