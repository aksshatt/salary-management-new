import { Button, Layout, Space, Typography } from 'antd'
import { Link } from 'react-router'

export default function AppLayout({ user, onLogout, children }) {
  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Layout.Header style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <Space size="large">
          <Typography.Text strong style={{ color: '#fff' }}>
            Salary Management
          </Typography.Text>
          <Link to="/" style={{ color: 'rgba(255,255,255,0.85)' }}>
            Dashboard
          </Link>
          <Link to="/employees" style={{ color: 'rgba(255,255,255,0.85)' }}>
            Employees
          </Link>
          <Link to="/payroll" style={{ color: 'rgba(255,255,255,0.85)' }}>
            Payroll
          </Link>
          <Link to="/currencies" style={{ color: 'rgba(255,255,255,0.85)' }}>
            Currencies
          </Link>
          <Link to="/countries" style={{ color: 'rgba(255,255,255,0.85)' }}>
            Countries
          </Link>
          <Link to="/audit" style={{ color: 'rgba(255,255,255,0.85)' }}>
            Audit
          </Link>
        </Space>
        <Space>
          <Typography.Text style={{ color: 'rgba(255,255,255,0.75)' }}>{user.email_address}</Typography.Text>
          <Button size="small" onClick={onLogout}>
            Log out
          </Button>
        </Space>
      </Layout.Header>
      <Layout.Content style={{ padding: 24 }}>{children}</Layout.Content>
    </Layout>
  )
}
