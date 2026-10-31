import { Select, Space, Typography } from 'antd'
import { useEffect, useState } from 'react'
import { useLocation, useNavigate } from 'react-router'
import { apiFetch } from './api.js'
import { TYPE_LABELS } from './auditFormat.js'
import AuditTable from './AuditTable.jsx'

const TYPE_OPTIONS = [
  { value: 'Employee', label: 'Employees' },
  { value: 'SalaryRevision', label: 'Salary revisions' },
  { value: 'PayrollEntry', label: 'Payroll adjustments' },
  { value: 'PayrollRun', label: 'Payroll runs' },
  { value: 'Country', label: 'Tax rates' },
  { value: 'ExchangeRate', label: 'Exchange rates' },
]

function queryString(type, page) {
  const params = new URLSearchParams()
  if (type) params.set('type', type)
  if (page > 1) params.set('page', page)
  const search = params.toString()
  return search ? `?${search}` : ''
}

export default function AuditPage() {
  const location = useLocation()
  const navigate = useNavigate()
  const params = new URLSearchParams(location.search)
  const type = TYPE_LABELS[params.get('type')] ? params.get('type') : ''
  const page = Math.max(Number.parseInt(params.get('page'), 10) || 1, 1)
  const search = queryString(type, page)
  const [data, setData] = useState({ events: [], total: 0, per_page: 25 })

  useEffect(() => {
    apiFetch(`/audit_events${search}`).then(setData)
  }, [search])

  return (
    <>
      <Typography.Title level={3}>Audit</Typography.Title>
      <Typography.Paragraph type="secondary">Every change to employees, salaries, payroll and rates.</Typography.Paragraph>
      <Space style={{ marginBottom: 16 }}>
        <Select
          aria-label="Type"
          placeholder="All types"
          allowClear
          value={type || undefined}
          options={TYPE_OPTIONS}
          onChange={(value) => navigate(`/audit${queryString(value ?? '', 1)}`)}
          style={{ width: 220 }}
        />
      </Space>
      <AuditTable
        events={data.events}
        pagination={{
          current: page,
          pageSize: data.per_page,
          total: data.total,
          showSizeChanger: false,
          showTotal: (total) => `${total} changes`,
          onChange: (next) => navigate(`/audit${queryString(type, next)}`),
        }}
      />
    </>
  )
}
