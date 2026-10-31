// @vitest-environment jsdom
import './test/antdDom.js'
import { cleanup, fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes, useLocation } from 'react-router'
import { afterEach, describe, expect, it, vi } from 'vitest'
import AuditPage from './AuditPage.jsx'

afterEach(() => {
  cleanup()
  vi.unstubAllGlobals()
})

const event = {
  id: 9, type: 'Employee', label: 'Priya Nair', employee_id: 7, action: 'update',
  changes: { job_title: ['Engineer', 'Senior Engineer'] }, created_at: '2026-10-02T09:00:00.000Z',
}

function stubApi(body = { events: [event], total: 1, page: 1, per_page: 25 }) {
  const fetch = vi.fn(() => Promise.resolve({ ok: true, status: 200, json: () => Promise.resolve(body) }))
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
        <Route path="/audit" element={<AuditPage />} />
      </Routes>
      <CurrentLocation />
    </MemoryRouter>,
  )
}

describe('AuditPage', () => {
  it('lists changes newest first with when, what and how it changed', async () => {
    const fetch = stubApi()

    renderAt('/audit?type=Employee&page=2')

    const row = (await screen.findByText('Priya Nair')).closest('tr')
    expect(fetch.mock.calls[0][0]).toBe('/api/audit_events?type=Employee&page=2')
    expect(within(row).getByText('Employee')).toBeTruthy()
    expect(within(row).getByText('Updated')).toBeTruthy()
    expect(within(row).getByText('Job title: Engineer → Senior Engineer')).toBeTruthy()
    expect(within(row).getByText('2026-10-02 09:00 UTC')).toBeTruthy()
  })

  it('filters by type through the URL, back to page 1', async () => {
    stubApi()
    renderAt('/audit?page=3')
    await screen.findByText('Priya Nair')

    fireEvent.mouseDown(screen.getByLabelText('Type'))
    fireEvent.click(await screen.findByTitle('Salary revisions'))

    await waitFor(() => expect(screen.getByTestId('location').textContent).toBe('?type=SalaryRevision'))
  })

  it('pages through the URL', async () => {
    const events = Array.from({ length: 25 }, (_, i) => ({ ...event, id: i + 1, label: `Person ${i + 1}` }))
    stubApi({ events, total: 40, page: 1, per_page: 25 })
    renderAt('/audit')
    await screen.findByText('Person 1')

    expect(screen.getByText('40 changes')).toBeTruthy()
    fireEvent.click(screen.getByTitle('2'))

    await waitFor(() => expect(screen.getByTestId('location').textContent).toBe('?page=2'))
  })
})
