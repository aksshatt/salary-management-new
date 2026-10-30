import { Button, Layout, Space, Typography } from 'antd'

export default function AppLayout({ user, onLogout, children }) {
  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Layout.Header style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <Typography.Text strong style={{ color: '#fff' }}>
          Salary Management
        </Typography.Text>
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
