// @vitest-environment jsdom
import { cleanup, render, screen } from '@testing-library/react'
import { MemoryRouter, useLocation } from 'react-router'
import { afterEach, beforeAll, describe, expect, it, vi } from 'vitest'
import App from './App.jsx'

beforeAll(() => {
  window.matchMedia ??= () => ({ matches: false, addEventListener() {}, removeEventListener() {} })
})

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
})
