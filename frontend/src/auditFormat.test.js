import { describe, expect, it } from 'vitest'
import { describeChanges } from './auditFormat.js'

describe('describeChanges', () => {
  it('turns each changed field into a readable line', () => {
    expect(
      describeChanges({ job_title: ['Engineer', 'Senior Engineer'], terminated_on: [null, '2026-10-31'] }),
    ).toEqual(['Job title: Engineer → Senior Engineer', 'Terminated on: — → 2026-10-31'])
  })

  it('leaves out internal ids and the employee code', () => {
    expect(describeChanges({ country_id: [null, 3], code: [null, 'EMP-00001'], name: [null, 'Priya'] })).toEqual([
      'Name: — → Priya',
    ])
  })
})
