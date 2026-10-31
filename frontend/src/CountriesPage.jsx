import { Button, Table, Typography } from 'antd'
import { useCallback, useEffect, useState } from 'react'
import { apiFetch } from './api.js'
import EditTaxRateModal from './EditTaxRateModal.jsx'

export default function CountriesPage() {
  const [countries, setCountries] = useState([])
  const [editing, setEditing] = useState(null)

  const load = useCallback(() => {
    apiFetch('/countries').then((data) => setCountries(data.countries))
  }, [])

  useEffect(load, [load])

  const columns = [
    { title: 'Country', dataIndex: 'name' },
    { title: 'Currency', dataIndex: 'currency_code' },
    { title: 'Tax rate', dataIndex: 'tax_rate_percent', align: 'right', render: (rate) => `${rate}%` },
    {
      title: '',
      key: 'actions',
      render: (_, country) => (
        <Button size="small" onClick={() => setEditing(country)}>
          Edit tax rate
        </Button>
      ),
    },
  ]

  return (
    <>
      <Typography.Title level={3}>Countries</Typography.Title>
      <Typography.Paragraph type="secondary">One flat tax rate per country, used by payroll.</Typography.Paragraph>
      <Table rowKey="id" columns={columns} dataSource={countries} pagination={false} />
      {editing && (
        <EditTaxRateModal
          country={editing}
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
