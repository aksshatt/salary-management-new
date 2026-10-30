import { describe, expect, it } from 'vitest'
import { toFieldErrors } from './formErrors.js'

describe('toFieldErrors', () => {
  it("turns the API's errors object into Ant Design form field errors", () => {
    expect(
      toFieldErrors({ effective_on: ["can't be before the join date (2024-01-15)"], amount: ['must be greater than 0'] }),
    ).toEqual([
      { name: 'effective_on', errors: ["can't be before the join date (2024-01-15)"] },
      { name: 'amount', errors: ['must be greater than 0'] },
    ])
  })
})
