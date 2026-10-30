// @vitest-environment jsdom
import './test/antdDom.js'
import { cleanup, fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router'
import { afterEach, describe, expect, it, vi } from 'vitest'
import EmployeeDetailPage from './EmployeeDetailPage.jsx'

afterEach(() => {
  cleanup()
  vi.unstubAllGlobals()
})

const employee = {
  id: 7,
  code: 'EMP-00007',
  name: 'Priya Nair',
  email: 'priya@acme.test',
  country: { id: 3, name: 'India', currency_code: 'INR' },
  department: 'Sales',
  job_title: 'Account Manager',
  joined_on: '2024-01-15',
  terminated_on: null,
  status: 'active',
  bank_account: '••••3210',
  current_salary: { amount: '1320000.50', currency_code: 'INR' },
  salary_revisions: [
    { id: 2, effective_on: '2025-04-01', amount: '1320000.50', currency_code: 'INR', reason: 'increment' },
    { id: 1, effective_on: '2024-01-15', amount: '1200000.00', currency_code: 'INR', reason: 'initial' },
  ],
}

function jsonResponse(status, body) {
  return { ok: status >= 200 && status < 300, status, json: () => Promise.resolve(body) }
}

const editOptions = {
  countries: [
    { id: 3, name: 'India', currency_code: 'INR' },
    { id: 4, name: 'Germany', currency_code: 'EUR' },
  ],
  departments: [],
  job_titles: [],
}

async function openEditDialog(patchResponse) {
  vi.stubGlobal(
    'fetch',
    vi.fn((url, request) => {
      if (url === '/api/filter_options') return Promise.resolve(jsonResponse(200, editOptions))
      if (request?.method === 'PATCH') return Promise.resolve(patchResponse)
      return Promise.resolve(jsonResponse(200, { employee }))
    }),
  )
  renderAt('/employees/7')
  await screen.findByRole('heading', { name: 'Priya Nair' })
  fireEvent.click(screen.getByRole('button', { name: 'Edit' }))
  return screen.findByRole('dialog')
}

function renderAt(path) {
  render(
    <MemoryRouter initialEntries={[path]}>
      <Routes>
        <Route path="/employees/:id" element={<EmployeeDetailPage />} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('EmployeeDetailPage', () => {
  it('shows the details, current salary and salary history, newest first', async () => {
    const fetch = vi.fn().mockResolvedValue(jsonResponse(200, { employee }))
    vi.stubGlobal('fetch', fetch)

    renderAt('/employees/7')

    expect(await screen.findByRole('heading', { name: 'Priya Nair' })).toBeTruthy()
    expect(fetch.mock.calls[0][0]).toBe('/api/employees/7')
    for (const text of ['EMP-00007', 'India', 'Sales', 'Account Manager', '••••3210']) {
      expect(screen.getByText(text)).toBeTruthy()
    }
    expect(screen.getByTestId('current-salary').textContent).toBe('₹1,320,000.50')

    const history = screen.getByRole('region', { name: 'Salary history' })
    const rows = within(history).getAllByRole('row').slice(1)
    expect(rows.map((row) => row.textContent)).toEqual([
      '2025-04-01₹1,320,000.50Increment',
      '2024-01-15₹1,200,000.00Initial',
    ])
  })

  it('says so when the employee does not exist', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(jsonResponse(404, { error: 'Not found' })))

    renderAt('/employees/999')

    expect(await screen.findByText('Employee not found')).toBeTruthy()
  })

  it('shows other load errors with the reason', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(jsonResponse(500, { error: 'Something broke' })))

    renderAt('/employees/7')

    expect(await screen.findByText('Could not load employee: Something broke')).toBeTruthy()
  })

  it('adds a salary revision and shows it in the history', async () => {
    const added = { id: 3, effective_on: '2026-04-01', amount: '1450000.00', currency_code: 'INR', reason: 'promotion' }
    const fetch = vi
      .fn()
      .mockResolvedValueOnce(jsonResponse(200, { employee }))
      .mockResolvedValueOnce(jsonResponse(201, { salary_revision: added }))
      .mockResolvedValueOnce(
        jsonResponse(200, { employee: { ...employee, salary_revisions: [added, ...employee.salary_revisions] } }),
      )
    vi.stubGlobal('fetch', fetch)
    renderAt('/employees/7')
    await screen.findByRole('heading', { name: 'Priya Nair' })

    fireEvent.click(screen.getByRole('button', { name: 'Add revision' }))
    const dialog = await screen.findByRole('dialog')
    fireEvent.change(within(dialog).getByLabelText('Effective from'), { target: { value: '2026-04-01' } })
    fireEvent.change(within(dialog).getByLabelText('Annual salary (INR)'), { target: { value: '1450000' } })
    fireEvent.mouseDown(within(dialog).getByLabelText('Reason'))
    fireEvent.click(await screen.findByTitle('Promotion'))
    fireEvent.click(within(dialog).getByRole('button', { name: 'Save' }))

    await waitFor(() => expect(fetch).toHaveBeenCalledTimes(3))
    expect(fetch.mock.calls[1][0]).toBe('/api/employees/7/salary_revisions')
    expect(JSON.parse(fetch.mock.calls[1][1].body)).toEqual({
      salary_revision: { effective_on: '2026-04-01', amount: '1450000', reason: 'promotion' },
    })
    const history = screen.getByRole('region', { name: 'Salary history' })
    expect(await within(history).findByText('₹1,450,000.00')).toBeTruthy()
  })

  it("shows the API's validation errors next to the fields and keeps the dialog open", async () => {
    vi.stubGlobal(
      'fetch',
      vi
        .fn()
        .mockResolvedValueOnce(jsonResponse(200, { employee }))
        .mockResolvedValueOnce(
          jsonResponse(422, { errors: { effective_on: ["can't be before the join date (2024-01-15)"] } }),
        ),
    )
    renderAt('/employees/7')
    await screen.findByRole('heading', { name: 'Priya Nair' })

    fireEvent.click(screen.getByRole('button', { name: 'Add revision' }))
    const dialog = await screen.findByRole('dialog')
    fireEvent.change(within(dialog).getByLabelText('Effective from'), { target: { value: '2023-12-01' } })
    fireEvent.change(within(dialog).getByLabelText('Annual salary (INR)'), { target: { value: '1450000' } })
    fireEvent.mouseDown(within(dialog).getByLabelText('Reason'))
    fireEvent.click(await screen.findByTitle('Correction'))
    fireEvent.click(within(dialog).getByRole('button', { name: 'Save' }))

    expect(await within(dialog).findByText("can't be before the join date (2024-01-15)")).toBeTruthy()
    expect(screen.getByRole('dialog')).toBeTruthy()
  })

  it('edits the details, keeping the bank account number when left empty', async () => {
    const options = { countries: [{ id: 3, name: 'India', currency_code: 'INR' }], departments: ['Sales'], job_titles: [] }
    const fetch = vi.fn((url, request) => {
      if (url === '/api/filter_options') return Promise.resolve(jsonResponse(200, options))
      if (request?.method === 'PATCH') return Promise.resolve(jsonResponse(200, { employee: { ...employee, name: 'Priya N.' } }))
      const renamed = fetch.mock.calls.some(([, r]) => r?.method === 'PATCH')
      return Promise.resolve(jsonResponse(200, { employee: { ...employee, name: renamed ? 'Priya N.' : 'Priya Nair' } }))
    })
    vi.stubGlobal('fetch', fetch)
    renderAt('/employees/7')
    await screen.findByRole('heading', { name: 'Priya Nair' })

    fireEvent.click(screen.getByRole('button', { name: 'Edit' }))
    const dialog = await screen.findByRole('dialog')
    expect(within(dialog).getByLabelText('Email').value).toBe('priya@acme.test')
    expect(within(dialog).getByLabelText('Join date').disabled).toBe(true)
    expect(within(dialog).getByLabelText('Bank account number').value).toBe('')
    fireEvent.change(within(dialog).getByLabelText('Name'), { target: { value: 'Priya N.' } })
    fireEvent.click(within(dialog).getByRole('button', { name: 'Save' }))

    expect(await screen.findByRole('heading', { name: 'Priya N.' })).toBeTruthy()
    const [url, request] = fetch.mock.calls.find(([, r]) => r?.method === 'PATCH')
    expect(url).toBe('/api/employees/7')
    expect(JSON.parse(request.body)).toEqual({
      employee: { name: 'Priya N.', email: 'priya@acme.test', country_id: '3', department: 'Sales', job_title: 'Account Manager' },
    })
  })

  it('warns that a new country only affects future salaries', async () => {
    const dialog = await openEditDialog()

    fireEvent.mouseDown(within(dialog).getByLabelText('Country'))
    fireEvent.click(await screen.findByTitle('Germany'))

    expect(
      (await within(dialog).findByRole('alert')).textContent,
    ).toContain('New salary revisions will be in EUR. Existing salaries stay in INR.')
  })

  it("shows the API's errors next to the fields when saving fails", async () => {
    const dialog = await openEditDialog(jsonResponse(422, { errors: { email: ['has already been taken'] } }))

    fireEvent.change(within(dialog).getByLabelText('Email'), { target: { value: 'taken@acme.test' } })
    fireEvent.click(within(dialog).getByRole('button', { name: 'Save' }))

    expect(await within(dialog).findByText('has already been taken')).toBeTruthy()
  })

  it('shows the status and, once set, the last working day', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue(
        jsonResponse(200, { employee: { ...employee, status: 'terminated', terminated_on: '2025-06-30' } }),
      ),
    )

    renderAt('/employees/7')

    expect(await screen.findByText('Terminated')).toBeTruthy()
    expect(screen.getByText('2025-06-30')).toBeTruthy()
  })

  it('terminates after a warning, then hides the Terminate button', async () => {
    let terminated = false
    const fetch = vi.fn((url, request) => {
      if (request?.method === 'POST') {
        terminated = true
        return Promise.resolve(jsonResponse(200, { employee: { ...employee, terminated_on: '2026-10-31' } }))
      }
      const current = terminated ? { ...employee, terminated_on: '2026-10-31' } : employee
      return Promise.resolve(jsonResponse(200, { employee: current }))
    })
    vi.stubGlobal('fetch', fetch)
    renderAt('/employees/7')
    await screen.findByRole('heading', { name: 'Priya Nair' })

    const actions = screen.getByRole('group', { name: 'Employee actions' })
    fireEvent.click(within(actions).getByRole('button', { name: 'Terminate' }))
    const dialog = await screen.findByRole('dialog')
    expect(dialog.textContent).toContain("This can't be undone.")
    fireEvent.change(within(dialog).getByLabelText('Last working day'), { target: { value: '2026-10-31' } })
    fireEvent.click(within(dialog).getByRole('button', { name: 'Terminate' }))

    expect(await screen.findByText('2026-10-31')).toBeTruthy()
    const [url, request] = fetch.mock.calls.find(([, r]) => r?.method === 'POST')
    expect(url).toBe('/api/employees/7/termination')
    expect(JSON.parse(request.body)).toEqual({ terminated_on: '2026-10-31' })
    expect(within(screen.getByRole('group', { name: 'Employee actions' })).queryByRole('button', { name: 'Terminate' })).toBeNull()
  })

  it("shows the API's error next to the date when termination fails", async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn((url, request) =>
        Promise.resolve(
          request?.method === 'POST'
            ? jsonResponse(422, { errors: { terminated_on: ["can't be before the join date"] } })
            : jsonResponse(200, { employee }),
        ),
      ),
    )
    renderAt('/employees/7')
    await screen.findByRole('heading', { name: 'Priya Nair' })

    fireEvent.click(within(screen.getByRole('group', { name: 'Employee actions' })).getByRole('button', { name: 'Terminate' }))
    const dialog = await screen.findByRole('dialog')
    fireEvent.change(within(dialog).getByLabelText('Last working day'), { target: { value: '2023-01-01' } })
    fireEvent.click(within(dialog).getByRole('button', { name: 'Terminate' }))

    expect(await within(dialog).findByText("can't be before the join date")).toBeTruthy()
  })

  it('marks revisions that never applied', async () => {
    const revisions = [
      { id: 3, effective_on: '2026-11-01', amount: '1400000.00', currency_code: 'INR', reason: 'increment', never_applied: true },
      { id: 1, effective_on: '2024-01-15', amount: '1200000.00', currency_code: 'INR', reason: 'initial', never_applied: false },
    ]
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue(jsonResponse(200, { employee: { ...employee, terminated_on: '2026-10-31', salary_revisions: revisions } })),
    )

    renderAt('/employees/7')

    const history = await screen.findByRole('region', { name: 'Salary history' })
    const rows = (await within(history).findAllByRole('row')).slice(1)
    expect(rows.map((row) => row.textContent.includes('Never applied'))).toEqual([true, false])
  })
})
