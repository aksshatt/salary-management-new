import { describe, expect, it } from 'vitest'
import { authRedirect } from './auth.js'

describe('authRedirect', () => {
  it('waits while the session is still loading', () => {
    expect(authRedirect({ status: 'loading', pathname: '/employees' })).toBeNull()
  })

  it('sends a logged-out user to login, remembering where they were going', () => {
    expect(authRedirect({ status: 'loggedOut', pathname: '/employees/42' })).toBe('/login?next=%2Femployees%2F42')
  })

  it('sends a logged-out user on the home page to login without a next param', () => {
    expect(authRedirect({ status: 'loggedOut', pathname: '/' })).toBe('/login')
  })

  it('leaves a logged-out user on the login page', () => {
    expect(authRedirect({ status: 'loggedOut', pathname: '/login' })).toBeNull()
  })

  it('sends a logged-in user away from the login page to the next page', () => {
    expect(authRedirect({ status: 'loggedIn', pathname: '/login', search: '?next=%2Femployees' })).toBe('/employees')
  })

  it('ignores a next param that points to another site', () => {
    expect(authRedirect({ status: 'loggedIn', pathname: '/login', search: '?next=%2F%2Fevil.test' })).toBe('/')
  })

  it('leaves a logged-in user on other pages', () => {
    expect(authRedirect({ status: 'loggedIn', pathname: '/employees' })).toBeNull()
  })
})
