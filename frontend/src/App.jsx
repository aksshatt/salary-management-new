import { Spin } from 'antd'
import { lazy, Suspense } from 'react'
import { Navigate, Route, Routes, useLocation } from 'react-router'
import AppLayout from './AppLayout.jsx'
import { authRedirect } from './auth.js'
import LoginPage from './LoginPage.jsx'
import { useSession } from './useSession.js'

// Each page is its own chunk, so the login page doesn't download the app.
const DashboardPage = lazy(() => import('./DashboardPage.jsx'))
const EmployeesPage = lazy(() => import('./EmployeesPage.jsx'))
const EmployeeDetailPage = lazy(() => import('./EmployeeDetailPage.jsx'))
const CurrenciesPage = lazy(() => import('./CurrenciesPage.jsx'))

export default function App() {
  const { status, user, login, logout } = useSession()
  const location = useLocation()

  const redirect = authRedirect({ status, pathname: location.pathname, search: location.search })
  if (redirect) return <Navigate to={redirect} replace />

  if (status === 'loggedOut') return <LoginPage onLogin={login} />
  if (status === 'loading') {
    return <Spin size="large" aria-label="Loading" style={{ display: 'block', marginTop: '30vh' }} />
  }

  return (
    <AppLayout user={user} onLogout={logout}>
      <Suspense fallback={<Spin />}>
        <Routes>
          <Route path="/employees" element={<EmployeesPage />} />
          <Route path="/employees/:id" element={<EmployeeDetailPage />} />
          <Route path="/currencies" element={<CurrenciesPage />} />
          <Route path="/" element={<DashboardPage />} />
        </Routes>
      </Suspense>
    </AppLayout>
  )
}
