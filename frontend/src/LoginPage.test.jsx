// @vitest-environment jsdom
import './test/antdDom.js'
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import LoginPage from './LoginPage.jsx'


afterEach(cleanup)

function fillAndSubmit(email, password) {
  fireEvent.change(screen.getByLabelText('Email'), { target: { value: email } })
  fireEvent.change(screen.getByLabelText('Password'), { target: { value: password } })
  fireEvent.click(screen.getByRole('button', { name: 'Log in' }))
}

describe('LoginPage', () => {
  it('calls onLogin with the email and password', async () => {
    const onLogin = vi.fn().mockResolvedValue()
    render(<LoginPage onLogin={onLogin} />)

    fillAndSubmit('hr@acme.test', 'secret')

    await waitFor(() => expect(onLogin).toHaveBeenCalledWith('hr@acme.test', 'secret'))
  })

  it('shows the error message when login fails', async () => {
    const onLogin = vi.fn().mockRejectedValue(new Error('Invalid email or password'))
    render(<LoginPage onLogin={onLogin} />)

    fillAndSubmit('hr@acme.test', 'wrong')

    expect((await screen.findByRole('alert')).textContent).toContain('Invalid email or password')
  })

  it('does not submit twice while a login is in progress', async () => {
    const onLogin = vi.fn(() => new Promise(() => {}))
    render(<LoginPage onLogin={onLogin} />)

    fillAndSubmit('hr@acme.test', 'secret')
    await waitFor(() => expect(onLogin).toHaveBeenCalledTimes(1))

    // Ant Design ignores clicks on a button in its loading state. It applies
    // that state in an effect, so wait for it rather than checking once.
    await waitFor(() => expect(screen.getByRole('button', { name: /Log in/ }).className).toContain('ant-btn-loading'))
  })
})
