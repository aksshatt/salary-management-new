// @vitest-environment jsdom
import './test/antdDom.js'
import { cleanup, fireEvent, render, screen, within } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import CountriesPage from './CountriesPage.jsx'

afterEach(() => {
  cleanup()
  vi.unstubAllGlobals()
})

const countries = [
  { id: 1, name: 'Brazil', currency_code: 'BRL', tax_rate_percent: '27.50' },
  { id: 2, name: 'India', currency_code: 'INR', tax_rate_percent: '20.00' },
]

function jsonResponse(status, body) {
  return { ok: status >= 200 && status < 300, status, json: () => Promise.resolve(body) }
}

function rowFor(name) {
  return screen.getByText(name).closest('tr')
}

describe('CountriesPage', () => {
  it('lists each country with its currency and tax rate', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(jsonResponse(200, { countries })))

    render(<CountriesPage />)

    await screen.findByText('Brazil')
    expect(rowFor('Brazil').textContent).toContain('BRL')
    expect(rowFor('Brazil').textContent).toContain('27.50%')
    expect(within(rowFor('India')).getByRole('button', { name: 'Edit tax rate' })).toBeTruthy()
  })

  it('edits a tax rate after warning that payroll needs a recalculation', async () => {
    let saved = false
    const fetch = vi.fn((url, request) => {
      if (request?.method === 'PATCH') {
        saved = true
        return Promise.resolve(jsonResponse(200, { country: { ...countries[1], tax_rate_percent: '22.50' } }))
      }
      const india = saved ? { ...countries[1], tax_rate_percent: '22.50' } : countries[1]
      return Promise.resolve(jsonResponse(200, { countries: [countries[0], india] }))
    })
    vi.stubGlobal('fetch', fetch)
    render(<CountriesPage />)
    await screen.findByText('India')

    fireEvent.click(within(rowFor('India')).getByRole('button', { name: 'Edit tax rate' }))
    const dialog = await screen.findByRole('dialog')
    expect(dialog.textContent).toContain('reaches the open payroll month when it is recalculated')
    expect(within(dialog).getByLabelText('Tax rate (%)').value).toBe('20.00')
    fireEvent.change(within(dialog).getByLabelText('Tax rate (%)'), { target: { value: '22.5' } })
    fireEvent.click(within(dialog).getByRole('button', { name: 'Save' }))

    expect(await screen.findByText('22.50%')).toBeTruthy()
    const [url, request] = fetch.mock.calls.find(([, r]) => r?.method === 'PATCH')
    expect(url).toBe('/api/countries/2')
    expect(JSON.parse(request.body)).toEqual({ country: { tax_rate_percent: '22.5' } })
  })

  it("shows the API's error next to the rate", async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn((url, request) =>
        Promise.resolve(
          request?.method === 'PATCH'
            ? jsonResponse(422, { errors: { tax_rate_percent: ['must be less than or equal to 100'] } })
            : jsonResponse(200, { countries }),
        ),
      ),
    )
    render(<CountriesPage />)
    await screen.findByText('India')

    fireEvent.click(within(rowFor('India')).getByRole('button', { name: 'Edit tax rate' }))
    const dialog = await screen.findByRole('dialog')
    fireEvent.click(within(dialog).getByRole('button', { name: 'Save' }))

    expect(await within(dialog).findByText('must be less than or equal to 100')).toBeTruthy()
  })
})
