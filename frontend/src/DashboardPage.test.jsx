// @vitest-environment jsdom
import './test/antdDom.js'
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes, useLocation } from 'react-router'
import { afterEach, describe, expect, it, vi } from 'vitest'
import DashboardPage from './DashboardPage.jsx'

// Charts draw on a canvas, which jsdom doesn't have; show their data instead.
vi.mock('@ant-design/charts', () => ({
  Pie: ({ data }) => <output data-testid="donut">{JSON.stringify(data)}</output>,
  Line: ({ data }) => <output data-testid="cost-trend">{JSON.stringify(data)}</output>,
  Column: ({ data }) => <output data-testid="movement">{JSON.stringify(data)}</output>,
  DualAxes: ({ data }) => <output data-testid="raises">{JSON.stringify(data)}</output>,
}))

afterEach(() => {
  cleanup()
  vi.unstubAllGlobals()
})

const insights = {
  month: '2026-09',
  as_of: '2026-09-30',
  stats: {
    headcount: 2, without_salary: 0, annual_cost: '150001.00', monthly_cost: '12500.08',
    average: '75000.50', median: '75000.50', lowest: '60000.00', highest: '90001.00',
  },
  breakdown: { group_by: 'country', groups: [{ name: 'United States', headcount: 2, annual_cost: '150001.00' }] },
}

const options = { countries: [{ id: 3, name: 'India', currency_code: 'INR' }], departments: ['Sales'], job_titles: [] }

function jsonResponse(status, body) {
  return { ok: status >= 200 && status < 300, status, json: () => Promise.resolve(body) }
}

const trends = {
  points: [
    { month: '2026-08', as_of: '2026-08-31', monthly_cost: '12000.00', joiners: 1, leavers: 0, raises: 0, average_raise_percent: null },
    { month: '2026-09', as_of: '2026-09-30', monthly_cost: '12500.08', joiners: 2, leavers: 1, raises: 3, average_raise_percent: '6.50' },
  ],
}

function stubApi(response = jsonResponse(200, insights)) {
  const fetch = vi.fn((url) => {
    if (url.startsWith('/api/filter_options')) return Promise.resolve(jsonResponse(200, options))
    if (url.startsWith('/api/insights/trends')) return Promise.resolve(jsonResponse(200, trends))
    return Promise.resolve(response)
  })
  vi.stubGlobal('fetch', fetch)
  return fetch
}

function CurrentLocation() {
  return <output data-testid="location">{useLocation().search}</output>
}

function renderAt(path) {
  render(
    <MemoryRouter initialEntries={[path]}>
      <Routes>
        <Route path="/" element={<DashboardPage />} />
      </Routes>
      <CurrentLocation />
    </MemoryRouter>,
  )
}

function tile(title) {
  return screen.getByText(title).closest('.ant-statistic').textContent.replace(title, '')
}

describe('DashboardPage', () => {
  it('loads the insights for the URL and shows the figures and the cost breakdown', async () => {
    const fetch = stubApi()

    renderAt('/?month=2026-09&department=Sales')

    expect(await screen.findByText('As of 2026-09-30')).toBeTruthy()
    expect(fetch.mock.calls.map(([url]) => url)).toContain('/api/insights?month=2026-09&department=Sales')
    expect(tile('Headcount')).toBe('2')
    expect(tile('Annual salary cost')).toBe('$150,001.00')
    expect(tile('Monthly salary cost')).toBe('$12,500.08')
    expect(tile('Average salary')).toBe('$75,000.50')
    expect(tile('Median salary')).toBe('$75,000.50')
    expect(tile('Lowest salary')).toBe('$60,000.00')
    expect(tile('Highest salary')).toBe('$90,001.00')
    expect(JSON.parse((await screen.findByTestId('donut')).textContent)).toEqual([{ name: 'United States', value: 150001 }])
  })

  it('puts the chosen month in the URL, keeping the filters', async () => {
    stubApi()
    renderAt('/?department=Sales')
    await screen.findByText('As of 2026-09-30')

    fireEvent.change(screen.getByLabelText('Month'), { target: { value: '2026-06' } })

    await waitFor(() => expect(screen.getByTestId('location').textContent).toBe('?month=2026-06&department=Sales'))
  })

  it('filters by country, department and job title', async () => {
    stubApi()
    renderAt('/?month=2026-09')
    await screen.findByText('As of 2026-09-30')

    fireEvent.mouseDown(screen.getByLabelText('Country'))
    fireEvent.click(await screen.findByTitle('India'))
    await waitFor(() => expect(screen.getByTestId('location').textContent).toBe('?month=2026-09&country_id=3'))
    fireEvent.mouseDown(screen.getByLabelText('Department'))
    fireEvent.click(await screen.findByTitle('Sales'))

    await waitFor(() => expect(screen.getByTestId('location').textContent).toBe('?month=2026-09&country_id=3&department=Sales'))
  })

  it('switches the cost breakdown to departments', async () => {
    stubApi()
    renderAt('/?month=2026-09')
    await screen.findByText('As of 2026-09-30')

    fireEvent.click(screen.getByRole('radio', { name: 'By department' }))

    await waitFor(() => expect(screen.getByTestId('location').textContent).toBe('?month=2026-09&group_by=department'))
  })

  it("shows the API's error, e.g. for a future month", async () => {
    stubApi(jsonResponse(422, { error: "Month can't be in the future" }))

    renderAt('/?month=2099-01')

    expect((await screen.findByRole('alert')).textContent).toContain("Month can't be in the future")
  })

  it('warns when some salaries could not be converted to USD', async () => {
    stubApi(jsonResponse(200, { ...insights, stats: { ...insights.stats, without_salary: 1 } }))

    renderAt('/')

    expect((await screen.findByRole('alert')).textContent).toContain(
      'Left out of the salary figures (no salary in USD): 1',
    )
  })

  it('loads the 12-month trends for the same month and filters and draws both charts', async () => {
    const fetch = stubApi()

    renderAt('/?month=2026-09&department=Sales&group_by=department')

    expect(JSON.parse((await screen.findByTestId('cost-trend')).textContent)).toEqual([
      { month: '2026-08', value: 12000 },
      { month: '2026-09', value: 12500.08 },
    ])
    expect(JSON.parse(screen.getByTestId('movement').textContent)).toHaveLength(4)
    expect(JSON.parse(screen.getByTestId('raises').textContent)).toEqual([
      { month: '2026-08', raises: 0, average: null },
      { month: '2026-09', raises: 3, average: 6.5 },
    ])
    expect(fetch.mock.calls.map(([url]) => url)).toContain('/api/insights/trends?month=2026-09&department=Sales')
  })

  it("doesn't reload the trends when only the donut grouping changes", async () => {
    const fetch = stubApi()
    renderAt('/?month=2026-09')
    await screen.findByTestId('cost-trend')

    fireEvent.click(screen.getByRole('radio', { name: 'By department' }))
    await waitFor(() => expect(screen.getByTestId('location').textContent).toBe('?month=2026-09&group_by=department'))
    await waitFor(() => expect(fetch.mock.calls.filter(([url]) => url.startsWith('/api/insights?')).length).toBe(2))

    expect(fetch.mock.calls.filter(([url]) => url.startsWith('/api/insights/trends')).length).toBe(1)
  })

  it('asks for filter options that match the other chosen filters', async () => {
    const fetch = stubApi()

    renderAt('/?month=2026-09&department=Sales&group_by=department')
    await screen.findByText('As of 2026-09-30')

    expect(fetch.mock.calls.map(([url]) => url)).toContain('/api/filter_options?department=Sales')
  })
})
