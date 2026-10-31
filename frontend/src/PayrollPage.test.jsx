// @vitest-environment jsdom
import './test/antdDom.js'
import { cleanup, fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes, useLocation } from 'react-router'
import { afterEach, describe, expect, it, vi } from 'vitest'
import PayrollPage from './PayrollPage.jsx'

afterEach(() => {
  cleanup()
  vi.unstubAllGlobals()
})

function jsonResponse(status, body) {
  return { ok: status >= 200 && status < 300, status, json: () => Promise.resolve(body) }
}

const runs = {
  payroll_runs: [
    { month: '2026-10', open: true, entries: 2, calculated_at: '2026-10-15T09:00:00.000Z' },
    { month: '2026-09', open: false, entries: 2, calculated_at: '2026-09-30T09:00:00.000Z' },
  ],
  generatable_months: [],
}

const priya = {
  id: 11, employee_id: 7, code: 'EMP-00007', name: 'Priya Nair', country: 'India', currency_code: 'INR',
  days_worked: 31, days_in_month: 31, annual_salary: '1200000.00', monthly_gross: '100000.00', bonus: '0.00',
  deduction: '0.00', note: null, tax_rate_percent: '20.00', tax: '20000.00', net: '80000.00', negative_net: false,
  bank_account: '••••3210',
}

function entriesFor(month, { open = true, outdated = false, entries = [priya] } = {}) {
  return {
    payroll_run: {
      month, open, outdated, calculated_at: '2026-10-15T09:00:00.000Z',
      totals: [{ currency_code: 'INR', entries: 1, monthly_gross: '100000.00', bonus: '0.00', deduction: '0.00', tax: '20000.00', net: '80000.00' }],
    },
    entries, total: entries.length, page: 1, per_page: 25,
  }
}

// Routes API calls by URL and method; `overrides` maps "METHOD path" to a response.
function stubApi(overrides = {}) {
  const fetch = vi.fn((url, request = {}) => {
    const key = `${request.method ?? 'GET'} ${url.split('?')[0]}`
    if (overrides[key]) return Promise.resolve(overrides[key])
    if (url.startsWith('/api/payroll_runs/2026-10/entries')) return Promise.resolve(jsonResponse(200, entriesFor('2026-10')))
    if (url.startsWith('/api/payroll_runs/2026-09/entries')) return Promise.resolve(jsonResponse(200, entriesFor('2026-09', { open: false })))
    return Promise.resolve(jsonResponse(200, runs))
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
        <Route path="/payroll" element={<PayrollPage />} />
      </Routes>
      <CurrentLocation />
    </MemoryRouter>,
  )
}

describe('PayrollPage', () => {
  it('shows the latest month by default, with its state, totals per currency and entries', async () => {
    const fetch = stubApi()

    renderAt('/payroll')

    const row = (await screen.findByText('Priya Nair')).closest('tr')
    expect(fetch.mock.calls.map(([url]) => url)).toContain('/api/payroll_runs/2026-10/entries')
    expect(screen.getByRole('heading', { name: 'Payroll 2026-10' })).toBeTruthy()
    expect(screen.getByText('Open')).toBeTruthy()
    for (const text of ['EMP-00007', '31/31', '₹100,000.00', '₹20,000.00', '₹80,000.00', '••••3210']) {
      expect(within(row).getByText(text)).toBeTruthy()
    }
    const totals = screen.getByRole('region', { name: 'Totals' })
    expect(within(totals).getByText('INR')).toBeTruthy()
  })

  it('switches to another month, which shows as locked', async () => {
    const fetch = stubApi()
    renderAt('/payroll')
    await screen.findByText('Priya Nair')

    fireEvent.mouseDown(screen.getByLabelText('Month'))
    fireEvent.click(await screen.findByTitle('2026-09 (locked)'))

    await waitFor(() => expect(screen.getByTestId('location').textContent).toBe('?month=2026-09'))
    expect(await screen.findByText('Locked')).toBeTruthy()
    expect(fetch.mock.calls.map(([url]) => url)).toContain('/api/payroll_runs/2026-09/entries')
  })

  it('generates a month the API allows and opens it', async () => {
    const created = { payroll_run: { month: '2026-11', open: true, entries: 2, calculated_at: '2026-11-02T09:00:00.000Z' } }
    const fetch = stubApi({
      'GET /api/payroll_runs': jsonResponse(200, { ...runs, generatable_months: ['2026-11'] }),
      'POST /api/payroll_runs': jsonResponse(201, created),
      'GET /api/payroll_runs/2026-11/entries': jsonResponse(200, entriesFor('2026-11')),
    })
    renderAt('/payroll')
    await screen.findByText('Priya Nair')

    fireEvent.click(screen.getByRole('button', { name: 'Generate 2026-11' }))

    await waitFor(() => expect(screen.getByTestId('location').textContent).toBe('?month=2026-11'))
    const [, request] = fetch.mock.calls.find(([, r]) => r?.method === 'POST')
    expect(JSON.parse(request.body)).toEqual({ month: '2026-11' })
  })

  it("shows the API's reason when a month can't be generated", async () => {
    stubApi({
      'GET /api/payroll_runs': jsonResponse(200, { ...runs, generatable_months: ['2026-11'] }),
      'POST /api/payroll_runs': jsonResponse(422, { error: 'The next payroll must be for 2026-11, which hasn\'t started yet' }),
    })
    renderAt('/payroll')
    await screen.findByText('Priya Nair')

    fireEvent.click(screen.getByRole('button', { name: 'Generate 2026-11' }))

    expect((await screen.findByRole('alert')).textContent).toContain("which hasn't started yet")
  })

  it('recalculates the open month after confirming', async () => {
    const fetch = stubApi({ 'POST /api/payroll_runs': jsonResponse(200, { payroll_run: runs.payroll_runs[0] }) })
    renderAt('/payroll')
    await screen.findByText('Priya Nair')

    fireEvent.click(screen.getByRole('button', { name: 'Recalculate' }))
    expect(fetch.mock.calls.some(([, r]) => r?.method === 'POST')).toBe(false)
    expect((await screen.findByText(/Bonuses, deductions and notes are kept/)).textContent).toContain('current salaries and tax rates')
    fireEvent.click(screen.getByRole('button', { name: 'Yes, recalculate' }))

    await waitFor(() => expect(fetch.mock.calls.some(([, r]) => r?.method === 'POST')).toBe(true))
    const [, request] = fetch.mock.calls.find(([, r]) => r?.method === 'POST')
    expect(JSON.parse(request.body)).toEqual({ month: '2026-10' })
  })

  it('warns when the open month is outdated', async () => {
    stubApi({ 'GET /api/payroll_runs/2026-10/entries': jsonResponse(200, entriesFor('2026-10', { outdated: true })) })
    renderAt('/payroll')

    expect((await screen.findByRole('alert')).textContent).toContain('Changes after last generation, please recalculate')
  })

  it("adjusts an entry's bonus, deduction and note, then shows the new amounts", async () => {
    let adjusted = false
    const after = { ...priya, deduction: '90000.00', note: 'Loan', net: '-10000.00', negative_net: true }
    const fetch = vi.fn((url, request = {}) => {
      if (request.method === 'PATCH') {
        adjusted = true
        return Promise.resolve(jsonResponse(200, { entry: after }))
      }
      if (url.startsWith('/api/payroll_runs/2026-10/entries')) {
        return Promise.resolve(jsonResponse(200, entriesFor('2026-10', { entries: [adjusted ? after : priya] })))
      }
      return Promise.resolve(jsonResponse(200, runs))
    })
    vi.stubGlobal('fetch', fetch)
    renderAt('/payroll')
    const row = (await screen.findByText('Priya Nair')).closest('tr')

    fireEvent.click(within(row).getByRole('button', { name: 'Adjust' }))
    const dialog = await screen.findByRole('dialog')
    fireEvent.change(within(dialog).getByLabelText('Deduction (INR)'), { target: { value: '90000' } })
    fireEvent.change(within(dialog).getByLabelText('Note'), { target: { value: 'Loan' } })
    fireEvent.click(within(dialog).getByRole('button', { name: 'Save' }))

    expect(await screen.findByText('Negative net')).toBeTruthy()
    const [url, request] = fetch.mock.calls.find(([, r]) => r?.method === 'PATCH')
    expect(url).toBe('/api/payroll_runs/2026-10/entries/11')
    expect(JSON.parse(request.body)).toEqual({ payroll_entry: { bonus: '0.00', deduction: '90000', note: 'Loan' } })
  })

  it("shows the API's errors next to the fields when an adjustment fails", async () => {
    stubApi({
      'PATCH /api/payroll_runs/2026-10/entries/11': jsonResponse(422, { errors: { bonus: ['can have at most 2 decimal places'] } }),
    })
    renderAt('/payroll')
    const row = (await screen.findByText('Priya Nair')).closest('tr')

    fireEvent.click(within(row).getByRole('button', { name: 'Adjust' }))
    const dialog = await screen.findByRole('dialog')
    fireEvent.click(within(dialog).getByRole('button', { name: 'Save' }))

    expect(await within(dialog).findByText('can have at most 2 decimal places')).toBeTruthy()
  })

  it('offers no changes on a locked month, even if data changed since', async () => {
    stubApi({ 'GET /api/payroll_runs/2026-09/entries': jsonResponse(200, entriesFor('2026-09', { open: false, outdated: true })) })
    renderAt('/payroll?month=2026-09')
    await screen.findByText('Priya Nair')

    expect(screen.getByText('Locked')).toBeTruthy()
    expect(screen.queryByRole('button', { name: 'Recalculate' })).toBeNull()
    expect(screen.queryByRole('button', { name: 'Adjust' })).toBeNull()
    expect(screen.queryByRole('alert')).toBeNull()
  })

  it('searches and pages the entries through the URL', async () => {
    const many = Array.from({ length: 25 }, (_, i) => ({ ...priya, id: i + 1, name: `Person ${i + 1}` }))
    const fetch = stubApi({
      'GET /api/payroll_runs/2026-10/entries': jsonResponse(200, { ...entriesFor('2026-10', { entries: many }), total: 60 }),
    })
    renderAt('/payroll?month=2026-10&page=2')
    await screen.findByText('Person 1')

    expect(fetch.mock.calls.map(([url]) => url)).toContain('/api/payroll_runs/2026-10/entries?page=2')
    expect(screen.getByText('60 entries')).toBeTruthy()
    const search = screen.getByPlaceholderText('Search name or code')
    fireEvent.change(search, { target: { value: 'nair' } })
    fireEvent.keyDown(search, { key: 'Enter', code: 'Enter', keyCode: 13 })

    await waitFor(() => expect(screen.getByTestId('location').textContent).toBe('?month=2026-10&q=nair'))
  })

  it('links to the Excel export of the chosen month', async () => {
    stubApi()
    renderAt('/payroll?month=2026-09')
    await screen.findByText('Priya Nair')

    expect(screen.getByRole('link', { name: /Export to Excel/ }).getAttribute('href')).toBe('/api/payroll_runs/2026-09/export.xlsx')
  })

  it('offers to generate the first payroll when there is none yet', async () => {
    const fetch = stubApi({ 'GET /api/payroll_runs': jsonResponse(200, { payroll_runs: [], generatable_months: ['2026-09', '2026-10'] }) })

    renderAt('/payroll')

    expect(await screen.findByRole('button', { name: 'Generate 2026-09' })).toBeTruthy()
    expect(screen.getByRole('button', { name: 'Generate 2026-10' })).toBeTruthy()
    expect(fetch.mock.calls.some(([url]) => url.includes('/entries'))).toBe(false)
  })
})
