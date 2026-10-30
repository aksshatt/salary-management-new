// @vitest-environment jsdom
import { act, renderHook, waitFor } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { apiFetch, setCsrfToken } from './api.js'
import { useSession } from './useSession.js'

function jsonResponse(status, body) {
  return { ok: status >= 200 && status < 300, status, json: () => Promise.resolve(body) }
}

describe('useSession', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
    setCsrfToken(null)
  })

  it('starts loading, then is logged in when the session exists', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(jsonResponse(200, { user: { email_address: 'hr@acme.test' }, csrf_token: 't1' })))

    const { result } = renderHook(() => useSession())

    expect(result.current.status).toBe('loading')
    await waitFor(() => expect(result.current.status).toBe('loggedIn'))
    expect(result.current.user).toEqual({ email_address: 'hr@acme.test' })
  })

  it('is logged out when the API returns 401', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(jsonResponse(401, { error: 'Not logged in' })))

    const { result } = renderHook(() => useSession())

    await waitFor(() => expect(result.current.status).toBe('loggedOut'))
    expect(result.current.user).toBeNull()
  })

  it('logs in, then sends the new CSRF token on the next write', async () => {
    const fetch = vi
      .fn()
      .mockResolvedValueOnce(jsonResponse(401, { error: 'Not logged in' }))
      .mockResolvedValueOnce(jsonResponse(201, { user: { email_address: 'hr@acme.test' }, csrf_token: 'fresh' }))
      .mockResolvedValueOnce({ ok: true, status: 204 })
    vi.stubGlobal('fetch', fetch)
    const { result } = renderHook(() => useSession())
    await waitFor(() => expect(result.current.status).toBe('loggedOut'))

    await act(() => result.current.login('hr@acme.test', 'secret'))

    expect(result.current.status).toBe('loggedIn')
    expect(JSON.parse(fetch.mock.calls[1][1].body)).toEqual({ email_address: 'hr@acme.test', password: 'secret' })
    await apiFetch('/anything', { method: 'POST' })
    expect(fetch.mock.calls[2][1].headers['X-CSRF-Token']).toBe('fresh')
  })

  it('logs out and stops sending the old CSRF token', async () => {
    const fetch = vi
      .fn()
      .mockResolvedValueOnce(jsonResponse(200, { user: { email_address: 'hr@acme.test' }, csrf_token: 't1' }))
      .mockResolvedValueOnce({ ok: true, status: 204 })
      .mockResolvedValueOnce(jsonResponse(200, {}))
    vi.stubGlobal('fetch', fetch)
    const { result } = renderHook(() => useSession())
    await waitFor(() => expect(result.current.status).toBe('loggedIn'))

    await act(() => result.current.logout())

    expect(fetch.mock.calls[1][1].method).toBe('DELETE')
    expect(result.current.status).toBe('loggedOut')
    await apiFetch('/anything', { method: 'POST' })
    expect(fetch.mock.calls[2][1].headers).not.toHaveProperty('X-CSRF-Token')
  })
})
