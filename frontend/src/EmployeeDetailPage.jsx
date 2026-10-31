import { Button, Card, Descriptions, Result, Space, Statistic, Table, Tag, Typography } from 'antd'
import { lazy, Suspense, useCallback, useEffect, useState } from 'react'
import AddRevisionModal from './AddRevisionModal.jsx'
import EditEmployeeModal from './EditEmployeeModal.jsx'
import EmployeeHistory from './EmployeeHistory.jsx'
import { useParams } from 'react-router'
import { apiFetch } from './api.js'
import { formatChange, formatMoney, formatSalaryWithUsd } from './format.js'
import StatusTag from './StatusTag.jsx'
import TerminateModal from './TerminateModal.jsx'

const SalaryTimeline = lazy(() => import('./SalaryTimeline.jsx'))

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
  { title: 'Change', dataIndex: 'change_percent', align: 'right', render: formatChange },
  {
    title: 'Reason',
    dataIndex: 'reason',
    render: (reason, revision) => (
      <>
        {REASON_LABELS[reason]}
        {revision.never_applied && <Tag style={{ marginLeft: 8 }}>Never applied</Tag>}
      </>
    ),
  },
]

export default function EmployeeDetailPage() {
  const { id } = useParams()
  const [employee, setEmployee] = useState(null)
  const [error, setError] = useState(null)
  const [adding, setAdding] = useState(false)
  const [editing, setEditing] = useState(false)
  const [terminating, setTerminating] = useState(false)

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
        <Space align="baseline">
          <Typography.Title level={3}>{employee.name}</Typography.Title>
          <StatusTag status={employee.status} />
        </Space>
        <Space role="group" aria-label="Employee actions">
          <Button onClick={() => setEditing(true)}>Edit</Button>
          {!employee.terminated_on && (
            <Button danger onClick={() => setTerminating(true)}>
              Terminate
            </Button>
          )}
        </Space>
      </Space>
      <Descriptions bordered size="small" column={2} style={{ marginBottom: 24 }}>
        <Descriptions.Item label="Code">{employee.code}</Descriptions.Item>
        <Descriptions.Item label="Email">{employee.email}</Descriptions.Item>
        <Descriptions.Item label="Country">{employee.country.name}</Descriptions.Item>
        <Descriptions.Item label="Department">{employee.department}</Descriptions.Item>
        <Descriptions.Item label="Job title">{employee.job_title}</Descriptions.Item>
        <Descriptions.Item label="Joined">{employee.joined_on}</Descriptions.Item>
        {employee.terminated_on && (
          <Descriptions.Item label="Last working day">{employee.terminated_on}</Descriptions.Item>
        )}
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
          valueRender={() => <span data-testid="current-salary">{formatSalaryWithUsd(employee.current_salary)}</span>}
        />
      </Card>
      <section aria-label="Salary history">
        <Typography.Title level={4}>Salary history</Typography.Title>
        <Suspense fallback={null}>
          <SalaryTimeline revisions={employee.salary_revisions} />
        </Suspense>
        <Table rowKey="id" columns={REVISION_COLUMNS} dataSource={employee.salary_revisions} pagination={false} />
      </section>
      <EmployeeHistory employeeId={employee.id} reloadKey={employee} />
      <EditEmployeeModal
        employee={employee}
        open={editing}
        onClose={() => setEditing(false)}
        onSaved={() => {
          setEditing(false)
          load()
        }}
      />
      <TerminateModal
        employee={employee}
        open={terminating}
        onClose={() => setTerminating(false)}
        onTerminated={() => {
          setTerminating(false)
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
