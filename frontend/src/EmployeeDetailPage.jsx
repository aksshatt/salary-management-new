import { Button, Card, Descriptions, Result, Space, Statistic, Table, Typography } from 'antd'
import { useCallback, useEffect, useState } from 'react'
import AddRevisionModal from './AddRevisionModal.jsx'
import EditEmployeeModal from './EditEmployeeModal.jsx'
import { useParams } from 'react-router'
import { apiFetch } from './api.js'
import { formatMoney } from './format.js'

const REASON_LABELS = {
  initial: 'Initial',
  increment: 'Increment',
  promotion: 'Promotion',
  correction: 'Correction',
  other: 'Other',
}

const REVISION_COLUMNS = [
  { title: 'Effective from', dataIndex: 'effective_on' },
  { title: 'Annual salary', render: (_, revision) => formatMoney(revision) },
  { title: 'Reason', dataIndex: 'reason', render: (reason) => REASON_LABELS[reason] },
]

export default function EmployeeDetailPage() {
  const { id } = useParams()
  const [employee, setEmployee] = useState(null)
  const [error, setError] = useState(null)
  const [adding, setAdding] = useState(false)
  const [editing, setEditing] = useState(false)

  const load = useCallback(() => {
    apiFetch(`/employees/${id}`)
      .then((data) => setEmployee(data.employee))
      .catch((e) => setError(e.status === 404 ? 'Employee not found' : `Could not load employee: ${e.message}`))
  }, [id])

  useEffect(load, [load])

  if (error) return <Result status="warning" title={error} />
  if (!employee) return null

  return (
    <>
      <Space style={{ width: '100%', justifyContent: 'space-between' }}>
        <Typography.Title level={3}>{employee.name}</Typography.Title>
        <Button onClick={() => setEditing(true)}>Edit</Button>
      </Space>
      <Descriptions bordered size="small" column={2} style={{ marginBottom: 24 }}>
        <Descriptions.Item label="Code">{employee.code}</Descriptions.Item>
        <Descriptions.Item label="Email">{employee.email}</Descriptions.Item>
        <Descriptions.Item label="Country">{employee.country.name}</Descriptions.Item>
        <Descriptions.Item label="Department">{employee.department}</Descriptions.Item>
        <Descriptions.Item label="Job title">{employee.job_title}</Descriptions.Item>
        <Descriptions.Item label="Joined">{employee.joined_on}</Descriptions.Item>
        <Descriptions.Item label="Bank account">{employee.bank_account}</Descriptions.Item>
      </Descriptions>
      <Card
        title="Salary"
        extra={
          <Button type="primary" onClick={() => setAdding(true)}>
            Add revision
          </Button>
        }
        style={{ marginBottom: 24 }}
      >
        <Statistic
          title="Current annual salary"
          valueRender={() => <span data-testid="current-salary">{formatMoney(employee.current_salary)}</span>}
        />
      </Card>
      <section aria-label="Salary history">
        <Typography.Title level={4}>Salary history</Typography.Title>
        <Table rowKey="id" columns={REVISION_COLUMNS} dataSource={employee.salary_revisions} pagination={false} />
      </section>
      <EditEmployeeModal
        employee={employee}
        open={editing}
        onClose={() => setEditing(false)}
        onSaved={() => {
          setEditing(false)
          load()
        }}
      />
      <AddRevisionModal
        employee={employee}
        open={adding}
        onClose={() => setAdding(false)}
        onAdded={() => {
          setAdding(false)
          load()
        }}
      />
    </>
  )
}
