import { describe, expect, it } from 'vitest'
import { costTrendData, donutData, movementData, raiseData, timelineData } from './chartData.js'

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

describe('timelineData', () => {
  it('lists salaries oldest first with their currency, for a step chart', () => {
    expect(
      timelineData([
        { id: 2, effective_on: '2025-04-01', amount: '1320000.50', currency_code: 'INR' },
        { id: 1, effective_on: '2024-01-15', amount: '1200000.00', currency_code: 'INR' },
      ]),
    ).toEqual([
      { date: '2024-01-15', value: 1200000, currency: 'INR' },
      { date: '2025-04-01', value: 1320000.5, currency: 'INR' },
    ])
  })
})

describe('raiseData', () => {
  it('gives the number of raises and the average raise % per month, with a gap when there were none', () => {
    expect(
      raiseData([
        { month: '2026-08', raises: 0, average_raise_percent: null },
        { month: '2026-09', raises: 12, average_raise_percent: '5.25' },
      ]),
    ).toEqual([
      { month: '2026-08', raises: 0, average: null },
      { month: '2026-09', raises: 12, average: 5.25 },
    ])
  })
})
