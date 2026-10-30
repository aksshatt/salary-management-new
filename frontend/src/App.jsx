import { Layout, Typography } from 'antd'
import { Route, Routes } from 'react-router'

function Home() {
  return <Typography.Title level={3}>Salary Management</Typography.Title>
}

export default function App() {
  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Layout.Content style={{ padding: 24 }}>
        <Routes>
          <Route path="*" element={<Home />} />
        </Routes>
      </Layout.Content>
    </Layout>
  )
}
