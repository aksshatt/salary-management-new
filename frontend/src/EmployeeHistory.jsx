import { Typography } from 'antd'
import { useEffect, useState } from 'react'
import { apiFetch } from './api.js'
import AuditTable from './AuditTable.jsx'

// One employee's audit events (their details, revisions and payroll adjustments).
export default function EmployeeHistory({ employeeId, reloadKey }) {
  const [data, setData] = useState({ events: [], total: 0, per_page: 25 })
  const [page, setPage] = useState(1)

  useEffect(() => {
    const pageParam = page > 1 ? `&page=${page}` : ''
    apiFetch(`/audit_events?employee_id=${employeeId}${pageParam}`).then(setData)
  }, [employeeId, page, reloadKey])

  return (
    <section aria-label="Change history" style={{ marginTop: 24 }}>
      <Typography.Title level={4}>Change history</Typography.Title>
      <AuditTable
        events={data.events}
        pagination={{ current: page, pageSize: data.per_page, total: data.total, showSizeChanger: false, onChange: setPage }}
      />
    </section>
  )
}
