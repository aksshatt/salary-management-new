import { Table, Typography } from 'antd'
import { describeChanges, TYPE_LABELS } from './auditFormat.js'

// Shown in UTC so everyone reading the log sees the same time.
const when = (iso) => `${iso.slice(0, 16).replace('T', ' ')} UTC`

const COLUMNS = [
  { title: 'When', dataIndex: 'created_at', render: when, width: 170 },
  { title: 'Type', dataIndex: 'type', render: (type) => TYPE_LABELS[type] },
  { title: 'Record', dataIndex: 'label' },
  { title: 'Action', dataIndex: 'action', render: (action) => (action === 'create' ? 'Created' : 'Updated') },
  {
    title: 'Changes',
    dataIndex: 'changes',
    render: (changes) => describeChanges(changes).map((line) => <Typography.Text key={line} style={{ display: 'block' }}>{line}</Typography.Text>),
  },
]

// The audit log as a table; `pagination` comes from the page that owns the URL.
export default function AuditTable({ events, pagination }) {
  return <Table rowKey="id" columns={COLUMNS} dataSource={events} pagination={pagination} size="small" />
}
