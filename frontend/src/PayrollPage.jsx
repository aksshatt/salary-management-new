import { Alert, Button, Card, Input, Popconfirm, Select, Space, Spin, Table, Tag, Typography } from 'antd'
import { useCallback, useEffect, useState } from 'react'
import { useLocation, useNavigate } from 'react-router'
import AdjustEntryModal from './AdjustEntryModal.jsx'
import { apiFetch } from './api.js'
import { formatMoney } from './format.js'
import { parsePayrollQuery, payrollQueryString } from './payrollQuery.js'

const money = (currency) => (amount) => formatMoney({ amount, currency_code: currency })

const ENTRY_COLUMNS = [
  { title: 'Code', dataIndex: 'code' },
  { title: 'Name', dataIndex: 'name' },
  { title: 'Country', dataIndex: 'country' },
  { title: 'Days', render: (_, entry) => `${entry.days_worked}/${entry.days_in_month}` },
  { title: 'Gross', dataIndex: 'monthly_gross', align: 'right', render: (v, e) => money(e.currency_code)(v) },
  { title: 'Bonus', dataIndex: 'bonus', align: 'right', render: (v, e) => money(e.currency_code)(v) },
  { title: 'Deduction', dataIndex: 'deduction', align: 'right', render: (v, e) => money(e.currency_code)(v) },
  { title: 'Tax', dataIndex: 'tax', align: 'right', render: (v, e) => money(e.currency_code)(v) },
  {
    title: 'Net',
    dataIndex: 'net',
    align: 'right',
    render: (v, e) => (
      <>
        {money(e.currency_code)(v)}
        {e.negative_net && <Tag color="red" style={{ marginLeft: 8 }}>Negative net</Tag>}
      </>
    ),
  },
  { title: 'Bank account', dataIndex: 'bank_account' },
]

const TOTAL_COLUMNS = [
  { title: 'Currency', dataIndex: 'currency_code' },
  { title: 'Entries', dataIndex: 'entries', align: 'right' },
  ...['monthly_gross', 'bonus', 'deduction', 'tax', 'net'].map((key) => ({
    title: { monthly_gross: 'Gross', bonus: 'Bonus', deduction: 'Deduction', tax: 'Tax', net: 'Net' }[key],
    dataIndex: key,
    align: 'right',
    render: (v, total) => money(total.currency_code)(v),
  })),
]

export default function PayrollPage() {
  const location = useLocation()
  const navigate = useNavigate()
  const query = parsePayrollQuery(location.search)
  const [runs, setRuns] = useState(null)
  const [data, setData] = useState(null)
  const [error, setError] = useState(null)
  const [adjusting, setAdjusting] = useState(null)
  const [reloads, setReloads] = useState(0)
  const month = query.month || runs?.payroll_runs[0]?.month

  const loadRuns = useCallback(() => apiFetch('/payroll_runs').then(setRuns), [])
  useEffect(() => {
    loadRuns()
  }, [loadRuns])

  // Generates a new month, or recalculates the open one (same endpoint).
  async function generate(target) {
    setError(null)
    try {
      await apiFetch('/payroll_runs', { method: 'POST', body: { month: target } })
      await loadRuns()
      updateQuery({ month: target, q: '', page: 1 })
    } catch (e) {
      setError(e.message)
    }
  }

  const entriesQuery = payrollQueryString({ ...query, month: '' })
  useEffect(() => {
    if (month) apiFetch(`/payroll_runs/${month}/entries${entriesQuery}`).then(setData)
  }, [month, entriesQuery, reloads])

  function updateQuery(changes) {
    navigate(`/payroll${payrollQueryString({ ...query, month, ...changes })}`)
  }

  if (!runs) return <Spin />

  const run = data?.payroll_run
  const columns = run?.open
    ? [
        ...ENTRY_COLUMNS,
        {
          title: '',
          key: 'adjust',
          render: (_, entry) => (
            <Button size="small" onClick={() => setAdjusting(entry)}>
              Adjust
            </Button>
          ),
        },
      ]
    : ENTRY_COLUMNS

  return (
    <>
      <Typography.Title level={3}>{month ? `Payroll ${month}` : 'Payroll'}</Typography.Title>
      <Space wrap style={{ marginBottom: 16 }}>
        <Select
          aria-label="Month"
          value={month}
          placeholder="No payroll yet"
          options={runs.payroll_runs.map((r) => ({ value: r.month, label: r.open ? `${r.month} (open)` : `${r.month} (locked)` }))}
          onChange={(value) => updateQuery({ month: value, q: '', page: 1 })}
          style={{ width: 180 }}
        />
        {runs.generatable_months.map((target) => (
          <Button key={target} type="primary" onClick={() => generate(target)}>
            Generate {target}
          </Button>
        ))}
      </Space>
      {error && <Alert type="error" showIcon message={error} style={{ marginBottom: 16 }} />}
      {run && (
        <Space direction="vertical" style={{ width: '100%' }} size="large">
          <Space>
            <Tag color={run.open ? 'green' : 'default'}>{run.open ? 'Open' : 'Locked'}</Tag>
            {run.open && (
              <Popconfirm
                title={`Recalculate ${month}?`}
                description="Amounts are recalculated from current salaries and tax rates. Bonuses, deductions and notes are kept."
                okText="Yes, recalculate"
                onConfirm={() => generate(month)}
              >
                <Button>Recalculate</Button>
              </Popconfirm>
            )}
          </Space>
          {run.open && run.outdated && (
            <Alert type="warning" showIcon message="Outdated" description="Changes after last generation, please recalculate" />
          )}
          <section aria-label="Totals">
            <Card size="small" title="Totals">
              <Table rowKey="currency_code" columns={TOTAL_COLUMNS} dataSource={run.totals} pagination={false} size="small" />
            </Card>
          </section>
          <Space wrap>
            <Input.Search
              key={query.q}
              defaultValue={query.q}
              placeholder="Search name or code"
              allowClear
              onSearch={(q) => updateQuery({ q, page: 1 })}
              style={{ width: 260 }}
            />
            {/* A plain link: the browser downloads the file with the login cookie. */}
            <Button href={`/api/payroll_runs/${month}/export.xlsx`}>Export to Excel</Button>
          </Space>
          <Table
            rowKey="id"
            columns={columns}
            dataSource={data.entries}
            pagination={{
              current: query.page,
              pageSize: data.per_page,
              total: data.total,
              showSizeChanger: false,
              showTotal: (total) => `${total} entries`,
              onChange: (page) => updateQuery({ page }),
            }}
          />
        </Space>
      )}
      {adjusting && (
        <AdjustEntryModal
          month={month}
          entry={adjusting}
          onClose={() => setAdjusting(null)}
          onSaved={() => {
            setAdjusting(null)
            setReloads((n) => n + 1)
          }}
        />
      )}
    </>
  )
}
