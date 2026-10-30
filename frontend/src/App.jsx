import { Spin } from 'antd'
import { Navigate, Route, Routes, useLocation } from 'react-router'
import AppLayout from './AppLayout.jsx'
import DashboardPage from './DashboardPage.jsx'
import CurrenciesPage from './CurrenciesPage.jsx'
import EmployeeDetailPage from './EmployeeDetailPage.jsx'
import EmployeesPage from './EmployeesPage.jsx'
import { authRedirect } from './auth.js'
import LoginPage from './LoginPage.jsx'
import { useSession } from './useSession.js'

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
      <Routes>
        <Route path="/employees" element={<EmployeesPage />} />
        <Route path="/employees/:id" element={<EmployeeDetailPage />} />
        <Route path="/currencies" element={<CurrenciesPage />} />
        <Route path="/" element={<DashboardPage />} />
      </Routes>
    </AppLayout>
  )
}
