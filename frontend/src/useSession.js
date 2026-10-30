import { useCallback, useEffect, useState } from 'react'
import { ApiError, apiFetch, setCsrfToken } from './api.js'

// Loads the current HR session and exposes login/logout.
export function useSession() {
  const [state, setState] = useState({ status: 'loading', user: null })

  const applySession = useCallback((data) => {
    setCsrfToken(data.csrf_token)
    setState({ status: 'loggedIn', user: data.user })
  }, [])

  const loggedOut = useCallback(() => {
    setCsrfToken(null)
    setState({ status: 'loggedOut', user: null })
  }, [])

  useEffect(() => {
    apiFetch('/session')
      .then(applySession)
      .catch((error) => {
        if (error instanceof ApiError && error.status === 401) loggedOut()
        else throw error
      })
  }, [applySession, loggedOut])

  const login = useCallback(
    async (emailAddress, password) => {
      const data = await apiFetch('/session', {
        method: 'POST',
        body: { email_address: emailAddress, password },
      })
      applySession(data)
    },
    [applySession],
  )

  const logout = useCallback(async () => {
    await apiFetch('/session', { method: 'DELETE' })
    loggedOut()
  }, [loggedOut])

  return { ...state, login, logout }
}
