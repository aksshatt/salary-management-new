// @vitest-environment jsdom
import './test/antdDom.js'
import { cleanup, render, screen } from '@testing-library/react'
import { MemoryRouter, useLocation } from 'react-router'
import { afterEach, describe, expect, it, vi } from 'vitest'
import App from './App.jsx'


afterEach(() => {
  cleanup()
  vi.unstubAllGlobals()
})

function jsonResponse(status, body) {
  return { ok: status >= 200 && status < 300, status, json: () => Promise.resolve(body) }
}

function CurrentLocation() {
  const location = useLocation()
  return <output data-testid="location">{location.pathname + location.search}</output>
}

function renderAt(path) {
  render(
    <MemoryRouter initialEntries={[path]}>
      <App />
      <CurrentLocation />
    </MemoryRouter>,
  )
}

describe('App', () => {
  it('sends a logged-out visitor to the login page, remembering the page', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(jsonResponse(401, { error: 'Not logged in' })))

    renderAt('/employees/42')

    expect(await screen.findByRole('button', { name: 'Log in' })).toBeTruthy()
    expect(screen.getByTestId('location').textContent).toBe('/login?next=%2Femployees%2F42')
  })

  it('shows the app with the HR email when logged in', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue(jsonResponse(200, { user: { email_address: 'hr@acme.test' }, csrf_token: 't1' })),
    )

    renderAt('/')

    expect(await screen.findByText('hr@acme.test')).toBeTruthy()
    expect(screen.getByRole('heading', { name: 'Welcome' })).toBeTruthy()
  })

  it('shows a loading indicator while checking the session', () => {
    vi.stubGlobal('fetch', vi.fn(() => new Promise(() => {})))

    renderAt('/')

    expect(screen.getByLabelText('Loading')).toBeTruthy()
  })

  it('shows the employees page at /employees, with a link in the header', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn((url) => {
        const body = url === '/api/session'
          ? { user: { email_address: 'hr@acme.test' }, csrf_token: 't1' }
          : url.startsWith('/api/filter_options')
            ? { countries: [], departments: [], job_titles: [] }
            : { employees: [], total: 0, page: 1, per_page: 25 }
        return Promise.resolve(jsonResponse(200, body))
      }),
    )

    renderAt('/employees')

    expect(await screen.findByRole('heading', { name: 'Employees' })).toBeTruthy()
    expect(screen.getByRole('link', { name: 'Employees' }).getAttribute('href')).toBe('/employees')
  })

  it("shows an employee's page at /employees/:id", async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn((url) => {
        const body =
          url === '/api/session'
            ? { user: { email_address: 'hr@acme.test' }, csrf_token: 't1' }
            : {
                employee: {
                  id: 7, code: 'EMP-00007', name: 'Priya Nair', email: 'priya@acme.test',
                  country: { id: 3, name: 'India', currency_code: 'INR' }, department: 'Sales',
                  job_title: 'Account Manager', joined_on: '2024-01-15', terminated_on: null, status: 'active',
                  bank_account: '••••3210', current_salary: null, salary_revisions: [],
                },
              }
        return Promise.resolve(jsonResponse(200, body))
      }),
    )

    renderAt('/employees/7')

    expect(await screen.findByRole('heading', { name: 'Priya Nair' })).toBeTruthy()
  })

  it('shows the currencies page at /currencies, with a link in the header', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn((url) =>
        Promise.resolve(
          jsonResponse(200, url === '/api/session' ? { user: { email_address: 'hr@acme.test' }, csrf_token: 't1' } : { exchange_rates: [] }),
        ),
      ),
    )

    renderAt('/currencies')

    expect(await screen.findByRole('heading', { name: 'Currencies' })).toBeTruthy()
    expect(screen.getByRole('link', { name: 'Currencies' }).getAttribute('href')).toBe('/currencies')
  })
})
