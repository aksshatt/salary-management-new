import { Button, Table, Typography } from 'antd'
import { useCallback, useEffect, useState } from 'react'
import { apiFetch } from './api.js'
import EditRateModal from './EditRateModal.jsx'

export default function CurrenciesPage() {
  const [rates, setRates] = useState([])
  const [editing, setEditing] = useState(null)

  const load = useCallback(() => {
    apiFetch('/exchange_rates').then((data) => setRates(data.exchange_rates))
  }, [])

  useEffect(load, [load])

  const columns = [
    { title: 'Currency', dataIndex: 'currency_code' },
    { title: 'Countries', dataIndex: 'countries', render: (countries) => countries.join(', ') },
    { title: 'Units per 1 USD', dataIndex: 'units_per_usd', align: 'right' },
    {
      title: '',
      key: 'actions',
      render: (_, rate) =>
        rate.currency_code === 'USD' ? <Typography.Text type="secondary">Fixed</Typography.Text> : (
          <Button size="small" onClick={() => setEditing(rate)}>
            Edit rate
          </Button>
        ),
    },
  ]

  return (
    <>
      <Typography.Title level={3}>Currencies</Typography.Title>
      <Typography.Paragraph type="secondary">
        Used to compare pay across countries in USD. Salaries and payroll stay in local currency.
      </Typography.Paragraph>
      <Table rowKey="currency_code" columns={columns} dataSource={rates} pagination={false} />
      {editing && (
        <EditRateModal
          rate={editing}
          onClose={() => setEditing(null)}
          onSaved={() => {
            setEditing(null)
            load()
          }}
        />
      )}
    </>
  )
}
