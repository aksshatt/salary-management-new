import { Alert, Button, Card, Form, Input, Typography } from 'antd'
import { useState } from 'react'

export default function LoginPage({ onLogin }) {
  const [error, setError] = useState(null)
  const [submitting, setSubmitting] = useState(false)

  async function handleFinish({ email, password }) {
    setSubmitting(true)
    setError(null)
    try {
      await onLogin(email, password)
    } catch (e) {
      setError(e.message)
      setSubmitting(false)
    }
  }

  return (
    <div style={{ display: 'flex', justifyContent: 'center', paddingTop: '15vh' }}>
      <Card style={{ width: 360 }}>
        <Typography.Title level={3}>Salary Management</Typography.Title>
        <Typography.Paragraph type="secondary">Log in with your HR account.</Typography.Paragraph>
        {error && <Alert type="error" message={error} showIcon style={{ marginBottom: 16 }} />}
        <Form layout="vertical" onFinish={handleFinish} requiredMark={false}>
          <Form.Item label="Email" name="email" rules={[{ required: true, message: 'Enter your email' }]}>
            <Input type="email" autoComplete="username" autoFocus />
          </Form.Item>
          <Form.Item label="Password" name="password" rules={[{ required: true, message: 'Enter your password' }]}>
            <Input.Password autoComplete="current-password" />
          </Form.Item>
          <Button type="primary" htmlType="submit" block loading={submitting}>
            Log in
          </Button>
        </Form>
      </Card>
    </div>
  )
}
