import { afterEach, describe, expect, it, vi } from 'vitest'
import { ApiError, apiFetch } from './api.js'

function jsonResponse(status, body) {
  return { ok: status >= 200 && status < 300, status, json: () => Promise.resolve(body) }
}

describe('apiFetch', () => {
  afterEach(() => vi.unstubAllGlobals())

  it('prefixes the path with /api and returns the parsed JSON', async () => {
    const fetch = vi.fn().mockResolvedValue(jsonResponse(200, { id: 1 }))
    vi.stubGlobal('fetch', fetch)

    await expect(apiFetch('/employees/1')).resolves.toEqual({ id: 1 })
    expect(fetch.mock.calls[0][0]).toBe('/api/employees/1')
  })

  it('sends a JSON body with the given method', async () => {
    const fetch = vi.fn().mockResolvedValue(jsonResponse(201, {}))
    vi.stubGlobal('fetch', fetch)

    await apiFetch('/employees', { method: 'POST', body: { name: 'Ana' } })

    const options = fetch.mock.calls[0][1]
    expect(options.method).toBe('POST')
    expect(options.headers['Content-Type']).toBe('application/json')
    expect(options.body).toBe('{"name":"Ana"}')
  })

  it('returns null for 204 No Content', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: true, status: 204 }))

    await expect(apiFetch('/session', { method: 'DELETE' })).resolves.toBeNull()
  })

  it('throws an ApiError with the status and error message on failure', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(jsonResponse(422, { error: 'Invalid date' })))

    const error = await apiFetch('/employees').catch((e) => e)

    expect(error).toBeInstanceOf(ApiError)
    expect(error.status).toBe(422)
    expect(error.message).toBe('Invalid date')
  })
})
