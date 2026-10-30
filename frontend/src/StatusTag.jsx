import { Tag } from 'antd'
import { STATUSES } from './statuses.js'

export default function StatusTag({ status }) {
  return <Tag color={STATUSES[status].color}>{STATUSES[status].label}</Tag>
}
