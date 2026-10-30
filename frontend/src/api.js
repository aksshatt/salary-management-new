export class ApiError extends Error {
  constructor(status, body) {
    super(body?.error ?? `Request failed with status ${status}`)
    this.status = status
    this.body = body
  }
}

const WRITE_METHODS = ['POST', 'PATCH', 'PUT', 'DELETE']
let csrfToken = null

export function setCsrfToken(token) {
  csrfToken = token
}

export async function apiFetch(path, { method = 'GET', body } = {}) {
  const response = await fetch(`/api${path}`, {
    method,
    credentials: 'same-origin',
    headers: {
      Accept: 'application/json',
      ...(body === undefined ? {} : { 'Content-Type': 'application/json' }),
      ...(WRITE_METHODS.includes(method) && csrfToken ? { 'X-CSRF-Token': csrfToken } : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  })

  const data = response.status === 204 ? null : await response.json().catch(() => null)
  if (!response.ok) throw new ApiError(response.status, data)
  return data
}
