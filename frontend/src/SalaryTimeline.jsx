import { Line } from '@ant-design/charts'
import { timelineData } from './chartData.js'

const number = new Intl.NumberFormat('en-US', { maximumFractionDigits: 2 })

// Annual salary over time in local currency. A salary holds until the next
// revision, so the line steps. One line per currency, so a country change
// never puts two currencies on one line. Loaded lazily: the charts library is large.
export default function SalaryTimeline({ revisions }) {
  return (
    <Line
      data={timelineData(revisions)}
      xField="date"
      yField="value"
      colorField="currency"
      shapeField="hv"
      point={{ shapeField: 'circle', sizeField: 3 }}
      height={260}
      axis={{ y: { labelFormatter: (value) => number.format(value) } }}
    />
  )
}
