// Decides where the router should send the user, given the session status.
// Returns a path to redirect to, or null to stay on the current page.
export function authRedirect({ status, pathname, search = '' }) {
  if (status === 'loading') return null

  const onLogin = pathname === '/login'

  if (status === 'loggedOut') {
    if (onLogin) return null
    return pathname === '/' ? '/login' : `/login?next=${encodeURIComponent(pathname)}`
  }

  if (onLogin) return safeNext(new URLSearchParams(search).get('next'))
  return null
}

// Only allow same-site paths, so a crafted link can't send the user elsewhere.
function safeNext(next) {
  return next && next.startsWith('/') && !next.startsWith('//') ? next : '/'
}
