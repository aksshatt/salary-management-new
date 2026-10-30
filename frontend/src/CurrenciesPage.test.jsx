// @vitest-environment jsdom
import './test/antdDom.js'
import { cleanup, fireEvent, render, screen, within } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import CurrenciesPage from './CurrenciesPage.jsx'

afterEach(() => {
  cleanup()
  vi.unstubAllGlobals()
})

const rates = [
  { currency_code: 'EUR', units_per_usd: '0.92', countries: ['France', 'Germany'] },
  { currency_code: 'USD', units_per_usd: '1.0', countries: ['United States'] },
]

function jsonResponse(status, body) {
  return { ok: status >= 200 && status < 300, status, json: () => Promise.resolve(body) }
}

function rowFor(code) {
  return screen.getByText(code).closest('tr')
}

describe('CurrenciesPage', () => {
  it('lists each currency with its countries and rate; USD is fixed', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(jsonResponse(200, { exchange_rates: rates })))

    render(<CurrenciesPage />)

    await screen.findByText('EUR')
    expect(rowFor('EUR').textContent).toContain('France, Germany')
    expect(rowFor('EUR').textContent).toContain('0.92')
    expect(within(rowFor('EUR')).getByRole('button', { name: 'Edit rate' })).toBeTruthy()
    expect(within(rowFor('USD')).queryByRole('button', { name: 'Edit rate' })).toBeNull()
    expect(rowFor('USD').textContent).toContain('Fixed')
  })

  it('edits a rate and shows the new value', async () => {
    let saved = false
    const fetch = vi.fn((url, request) => {
      if (request?.method === 'PATCH') {
        saved = true
        return Promise.resolve(jsonResponse(200, { exchange_rate: { ...rates[0], units_per_usd: '0.95' } }))
      }
      const current = saved ? [{ ...rates[0], units_per_usd: '0.95' }, rates[1]] : rates
      return Promise.resolve(jsonResponse(200, { exchange_rates: current }))
    })
    vi.stubGlobal('fetch', fetch)
    render(<CurrenciesPage />)
    await screen.findByText('EUR')

    fireEvent.click(within(rowFor('EUR')).getByRole('button', { name: 'Edit rate' }))
    const dialog = await screen.findByRole('dialog')
    expect(within(dialog).getByLabelText('EUR per 1 USD').value).toBe('0.92')
    fireEvent.change(within(dialog).getByLabelText('EUR per 1 USD'), { target: { value: '0.95' } })
    fireEvent.click(within(dialog).getByRole('button', { name: 'Save' }))

    expect(await within(await screen.findByText('0.95').then((cell) => cell.closest('tr'))).findByText('EUR')).toBeTruthy()
    const [url, request] = fetch.mock.calls.find(([, r]) => r?.method === 'PATCH')
    expect(url).toBe('/api/exchange_rates/EUR')
    expect(JSON.parse(request.body)).toEqual({ exchange_rate: { units_per_usd: '0.95' } })
  })

  it("shows the API's error next to the rate", async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn((url, request) =>
        Promise.resolve(
          request?.method === 'PATCH'
            ? jsonResponse(422, { errors: { units_per_usd: ['must be greater than 0'] } })
            : jsonResponse(200, { exchange_rates: rates }),
        ),
      ),
    )
    render(<CurrenciesPage />)
    await screen.findByText('EUR')

    fireEvent.click(within(rowFor('EUR')).getByRole('button', { name: 'Edit rate' }))
    const dialog = await screen.findByRole('dialog')
    fireEvent.click(within(dialog).getByRole('button', { name: 'Save' }))

    expect(await within(dialog).findByText('must be greater than 0')).toBeTruthy()
  })
})
