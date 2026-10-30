import { Alert, Button, Input, Select, Space, Table, Tag, Typography } from 'antd'
import { useEffect, useState } from 'react'
import { Link, useLocation, useNavigate } from 'react-router'
import AddEmployeeModal from './AddEmployeeModal.jsx'
import { apiFetch } from './api.js'
import { formatMoney } from './format.js'
import { employeeQueryString, parseEmployeeQuery } from './employeeQuery.js'

const STATUS_TAGS = {
  active: { color: 'green', label: 'Active' },
  upcoming: { color: 'blue', label: 'Upcoming' },
  terminated: { color: 'default', label: 'Terminated' },
}

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
    render: (status) => <Tag color={STATUS_TAGS[status].color}>{STATUS_TAGS[status].label}</Tag>,
  },
  { title: 'Annual salary', dataIndex: 'current_salary', align: 'right', render: formatMoney },
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

  useEffect(() => {
    apiFetch('/filter_options')
      .then(setOptions)
      .catch(() => {})
  }, [])

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
        <Button type="primary" onClick={() => setAdding(true)}>
          Add employee
        </Button>
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
        <Select
          aria-label="Country"
          placeholder="Country"
          allowClear
          value={query.country_id || undefined}
          options={options.countries.map((country) => ({ value: String(country.id), label: country.name }))}
          onChange={(value) => updateQuery({ country_id: value ?? '' })}
          style={{ width: 180 }}
        />
        <Select
          aria-label="Department"
          placeholder="Department"
          allowClear
          value={query.department || undefined}
          options={options.departments.map((department) => ({ value: department, label: department }))}
          onChange={(value) => updateQuery({ department: value ?? '' })}
          style={{ width: 180 }}
        />
        <Select
          aria-label="Job title"
          placeholder="Job title"
          allowClear
          value={query.job_title || undefined}
          options={options.job_titles.map((title) => ({ value: title, label: title }))}
          onChange={(value) => updateQuery({ job_title: value ?? '' })}
          style={{ width: 220 }}
        />
        <Select
          aria-label="Status"
          placeholder="Status"
          allowClear
          value={query.status || undefined}
          options={Object.entries(STATUS_TAGS).map(([value, { label }]) => ({ value, label }))}
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
        options={options}
        onClose={() => setAdding(false)}
        onAdded={(employee) => navigate(`/employees/${employee.id}`)}
      />
    </>
  )
}
