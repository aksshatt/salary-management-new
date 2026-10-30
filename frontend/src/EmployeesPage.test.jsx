// @vitest-environment jsdom
import './test/antdDom.js'
import { cleanup, fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes, useLocation } from 'react-router'
import { afterEach, describe, expect, it, vi } from 'vitest'
import EmployeesPage from './EmployeesPage.jsx'


afterEach(() => {
  cleanup()
  vi.unstubAllGlobals()
})

const priya = {
  id: 7,
  code: 'EMP-00007',
  name: 'Priya Nair',
  email: 'priya@acme.test',
  country: { id: 3, name: 'India', currency_code: 'INR' },
  department: 'Sales',
  job_title: 'Account Manager',
  joined_on: '2025-01-06',
  terminated_on: null,
  status: 'active',
  bank_account: '••••3210',
  current_salary: { amount: '1320000.50', currency_code: 'INR' },
}

function stubApi({ employees = [priya], total = employees.length } = {}) {
  const fetch = vi.fn((url) => {
    const body = url.startsWith('/api/filter_options')
      ? { countries: [{ id: 3, name: 'India', currency_code: 'INR' }], departments: ['Sales'], job_titles: ['Account Manager'] }
      : { employees, total, page: 1, per_page: 25 }
    return Promise.resolve({ ok: true, status: 200, json: () => Promise.resolve(body) })
  })
  vi.stubGlobal('fetch', fetch)
  return fetch
}

function CurrentLocation() {
  const location = useLocation()
  return <output data-testid="location">{location.search}</output>
}

// Opens an Ant Design select by its aria-label and picks an option.
async function choose(label, option) {
  fireEvent.mouseDown(screen.getByLabelText(label))
  fireEvent.click(await screen.findByTitle(option))
}

function renderAt(path) {
  render(
    <MemoryRouter initialEntries={[path]}>
      <Routes>
        <Route path="/employees" element={<EmployeesPage />} />
      </Routes>
      <CurrentLocation />
    </MemoryRouter>,
  )
}

describe('EmployeesPage', () => {
  it('loads employees for the filters in the URL and shows them', async () => {
    const fetch = stubApi()

    renderAt('/employees?department=Sales&page=2')

    const row = (await screen.findByText('Priya Nair')).closest('tr')
    for (const text of ['EMP-00007', 'India', 'Sales', 'Account Manager', 'Active', '••••3210', '₹1,320,000.50']) {
      expect(within(row).getByText(text)).toBeTruthy()
    }
    expect(fetch.mock.calls.map(([url]) => url)).toContain('/api/employees?department=Sales&page=2')
  })

  it('searches by name or code, going back to page 1', async () => {
    stubApi()
    renderAt('/employees?department=Sales&page=3')
    await screen.findByText('Priya Nair')

    const search = screen.getByPlaceholderText('Search name or code')
    fireEvent.change(search, { target: { value: 'nair' } })
    fireEvent.keyDown(search, { key: 'Enter', code: 'Enter', keyCode: 13 })

    await waitFor(() => expect(screen.getByTestId('location').textContent).toBe('?q=nair&department=Sales'))
  })

  it('shows the total and puts the chosen page in the URL', async () => {
    const employees = Array.from({ length: 25 }, (_, i) => ({ ...priya, id: i + 1, name: `Person ${i + 1}` }))
    stubApi({ employees, total: 60 })
    renderAt('/employees?status=active')
    await screen.findByText('Person 1')

    expect(screen.getByText('60 employees')).toBeTruthy()
    fireEvent.click(screen.getByTitle('2'))

    await waitFor(() => expect(screen.getByTestId('location').textContent).toBe('?status=active&page=2'))
  })

  it('filters by country using the countries from the API', async () => {
    stubApi()
    renderAt('/employees?page=2')
    await screen.findByText('Priya Nair')

    await choose('Country', 'India')

    await waitFor(() => expect(screen.getByTestId('location').textContent).toBe('?country_id=3'))
  })

  it('filters by department and job title using the values from the API', async () => {
    stubApi()
    renderAt('/employees')
    await screen.findByText('Priya Nair')

    await choose('Department', 'Sales')
    await waitFor(() => expect(screen.getByTestId('location').textContent).toBe('?department=Sales'))
    await choose('Job title', 'Account Manager')

    await waitFor(() =>
      expect(screen.getByTestId('location').textContent).toBe('?department=Sales&job_title=Account+Manager'),
    )
  })

  it('filters by status', async () => {
    stubApi()
    renderAt('/employees')
    await screen.findByText('Priya Nair')

    await choose('Status', 'Upcoming')

    await waitFor(() => expect(screen.getByTestId('location').textContent).toBe('?status=upcoming'))
  })

  it('shows an error when the employees cannot be loaded', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(() => Promise.resolve({ ok: false, status: 500, json: () => Promise.resolve({ error: 'Something broke' }) })),
    )

    renderAt('/employees')

    expect((await screen.findByRole('alert')).textContent).toContain('Could not load employees: Something broke')
  })

  it("links each name to the employee's page", async () => {
    stubApi()
    renderAt('/employees')

    const link = await screen.findByRole('link', { name: 'Priya Nair' })

    expect(link.getAttribute('href')).toBe('/employees/7')
  })
})
