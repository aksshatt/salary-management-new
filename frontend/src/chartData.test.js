import { describe, expect, it } from 'vitest'
import { donutData } from './chartData.js'

describe('donutData', () => {
  it('turns the cost breakdown into chart slices, skipping groups with no cost', () => {
    expect(
      donutData([
        { name: 'India', headcount: 3, annual_cost: '45000.50' },
        { name: 'Brazil', headcount: 1, annual_cost: null },
      ]),
    ).toEqual([{ name: 'India', value: 45000.5 }])
  })
})
