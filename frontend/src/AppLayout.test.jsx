// @vitest-environment jsdom
import './test/antdDom.js'
import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router'
import { afterEach, describe, expect, it, vi } from 'vitest'
import AppLayout from './AppLayout.jsx'


afterEach(cleanup)

describe('AppLayout', () => {
  it('shows the logged-in email and logs out on click', () => {
    const onLogout = vi.fn()
    render(
      <MemoryRouter>
        <AppLayout user={{ email_address: 'hr@acme.test' }} onLogout={onLogout}>
          <p>page</p>
        </AppLayout>
      </MemoryRouter>,
    )

    expect(screen.getByText('hr@acme.test')).toBeTruthy()
    expect(screen.getByText('page')).toBeTruthy()
    fireEvent.click(screen.getByRole('button', { name: 'Log out' }))
    expect(onLogout).toHaveBeenCalledTimes(1)
  })
})
