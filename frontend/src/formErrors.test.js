import { describe, expect, it, vi } from 'vitest'
import { ApiError } from './api.js'
import { showFieldErrors, toFieldErrors } from './formErrors.js'

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

describe('showFieldErrors', () => {
  it('puts a 422 response on the form fields', () => {
    const form = { setFields: vi.fn() }

    showFieldErrors(form, new ApiError(422, { errors: { email: ['has already been taken'] } }))

    expect(form.setFields).toHaveBeenCalledWith([{ name: 'email', errors: ['has already been taken'] }])
  })

  it('rethrows any other error', () => {
    const error = new ApiError(500, { error: 'boom' })

    expect(() => showFieldErrors({ setFields: vi.fn() }, error)).toThrow(error)
  })
})
