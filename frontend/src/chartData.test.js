import { describe, expect, it } from 'vitest'
import { costTrendData, donutData, movementData } from './chartData.js'

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

const points = [
  { month: '2026-08', as_of: '2026-08-31', monthly_cost: null, joiners: 0, leavers: 0 },
  { month: '2026-09', as_of: '2026-09-30', monthly_cost: '12500.08', joiners: 2, leavers: 1 },
]

describe('costTrendData', () => {
  it('plots the monthly cost, leaving a gap for months with no cost', () => {
    expect(costTrendData(points)).toEqual([
      { month: '2026-08', value: null },
      { month: '2026-09', value: 12500.08 },
    ])
  })
})

describe('movementData', () => {
  it('gives joiners and leavers side by side for each month', () => {
    expect(movementData(points)).toEqual([
      { month: '2026-08', type: 'Joiners', count: 0 },
      { month: '2026-08', type: 'Leavers', count: 0 },
      { month: '2026-09', type: 'Joiners', count: 2 },
      { month: '2026-09', type: 'Leavers', count: 1 },
    ])
  })
})
