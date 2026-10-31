import { Alert, Button, Input, Select, Space, Table, Typography } from 'antd'
import { useEffect, useState } from 'react'
import { Link, useLocation, useNavigate } from 'react-router'
import AddEmployeeModal from './AddEmployeeModal.jsx'
import EmployeeFilters from './EmployeeFilters.jsx'
import { apiFetch } from './api.js'
import { formatMoney } from './format.js'
import { STATUSES } from './statuses.js'
import StatusTag from './StatusTag.jsx'
import { employeeExportUrl, employeeQueryString, filterOptionsUrl, parseEmployeeQuery } from './employeeQuery.js'

const COLUMNS = [
  { title: 'Code', dataIndex: 'code' },
  { title: 'Name', dataIndex: 'name', render: (name, employee) => <Link to={`/employees/${employee.id}`}>{name}</Link> },
  { title: 'Country', dataIndex: ['country', 'name'] },
  { title: 'Department', dataIndex: 'department' },
  { title: 'Job title', dataIndex: 'job_title' },
  { title: 'Joined', dataIndex: 'joined_on' },
  {
    title: 'Status',
    dataIndex: 'status',
    render: (status) => <StatusTag status={status} />,
  },
  { title: 'Annual salary', dataIndex: 'current_salary', align: 'right', render: formatMoney },
  {
    title: 'In USD',
    dataIndex: 'current_salary',
    key: 'usd',
    align: 'right',
    render: (salary) => (salary?.usd ? formatMoney({ amount: salary.usd, currency_code: 'USD' }) : '—'),
  },
  { title: 'Bank account', dataIndex: 'bank_account' },
]

export default function EmployeesPage() {
  const location = useLocation()
  const navigate = useNavigate()
  const query = parseEmployeeQuery(location.search)
  const queryString = employeeQueryString(query)
  const [data, setData] = useState({ employees: [], total: 0 })
  const [error, setError] = useState(null)
  const [options, setOptions] = useState({ countries: [], departments: [], job_titles: [] })
  const [adding, setAdding] = useState(false)

  const optionsUrl = filterOptionsUrl(query)
  useEffect(() => {
    apiFetch(optionsUrl)
      .then(setOptions)
      .catch(() => {})
  }, [optionsUrl])

  useEffect(() => {
    apiFetch(`/employees${queryString}`)
      .then((result) => {
        setData(result)
        setError(null)
      })
      .catch((e) => setError(`Could not load employees: ${e.message}`))
  }, [queryString])

  // Any filter change starts again from the first page.
  function updateQuery(changes) {
    navigate(`/employees${employeeQueryString({ ...query, ...changes, page: 1 })}`)
  }

  return (
    <>
      <Space style={{ width: '100%', justifyContent: 'space-between' }}>
        <Typography.Title level={3}>Employees</Typography.Title>
        <Space>
          {/* A plain link: the browser downloads the file with the login cookie. */}
          <Button href={employeeExportUrl(query)}>Export CSV</Button>
          <Button type="primary" onClick={() => setAdding(true)}>
            Add employee
          </Button>
        </Space>
      </Space>
      <Space wrap style={{ marginBottom: 16 }}>
        <Input.Search
          key={query.q}
          defaultValue={query.q}
          placeholder="Search name or code"
          allowClear
          onSearch={(q) => updateQuery({ q })}
          style={{ width: 260 }}
        />
        <EmployeeFilters options={options} query={query} onChange={updateQuery} />
        <Select
          aria-label="Status"
          placeholder="Status"
          allowClear
          value={query.status || undefined}
          options={Object.entries(STATUSES).map(([value, { label }]) => ({ value, label }))}
          onChange={(value) => updateQuery({ status: value ?? '' })}
          style={{ width: 140 }}
        />
      </Space>
      {error && <Alert type="error" message={error} showIcon style={{ marginBottom: 16 }} />}
      <Table
        rowKey="id"
        columns={COLUMNS}
        dataSource={data.employees}
        pagination={{
          current: query.page,
          pageSize: 25,
          total: data.total,
          showSizeChanger: false,
          showTotal: (total) => `${total} employees`,
          onChange: (page) => navigate(`/employees${employeeQueryString({ ...query, page })}`),
        }}
      />
      <AddEmployeeModal
        open={adding}
        onClose={() => setAdding(false)}
        onAdded={(employee) => navigate(`/employees/${employee.id}`)}
      />
    </>
  )
}
