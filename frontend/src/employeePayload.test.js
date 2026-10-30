import { describe, expect, it } from 'vitest'
import { employeeUpdatePayload } from './employeePayload.js'

describe('employeeUpdatePayload', () => {
  const values = {
    name: 'Priya N.',
    email: 'priya@acme.test',
    country_id: '3',
    department: 'Sales',
    job_title: 'Account Manager',
    bank_account_number: '',
  }

  it('leaves out an empty bank account number so the current one is kept', () => {
    expect(employeeUpdatePayload(values)).toEqual({
      employee: { name: 'Priya N.', email: 'priya@acme.test', country_id: '3', department: 'Sales', job_title: 'Account Manager' },
    })
  })

  it('sends a newly entered bank account number', () => {
    expect(employeeUpdatePayload({ ...values, bank_account_number: 'DE89 3704' }).employee.bank_account_number).toBe('DE89 3704')
  })
})
