import { Pie } from '@ant-design/charts'
import { formatMoney } from './format.js'

// Loaded lazily: the charts library is large and only the dashboard needs it.
export default function CostDonut({ data }) {
  return (
    <Pie
      data={data}
      angleField="value"
      colorField="name"
      innerRadius={0.6}
      height={320}
      tooltip={{ items: [{ channel: 'y', valueFormatter: (value) => formatMoney({ amount: value, currency_code: 'USD' }) }] }}
      legend={{ color: { position: 'right' } }}
    />
  )
}
