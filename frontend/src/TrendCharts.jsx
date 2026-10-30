import { Column, Line } from '@ant-design/charts'
import { Card, Col, Row } from 'antd'
import { costTrendData, movementData } from './chartData.js'
import { formatMoney } from './format.js'

const usd = (value) => formatMoney({ amount: value, currency_code: 'USD' })

// Loaded lazily with the other charts.
export default function TrendCharts({ points }) {
  return (
    <Row gutter={[16, 16]}>
      <Col xs={24} lg={12}>
        <Card title="Monthly salary cost (12 months)">
          <Line
            data={costTrendData(points)}
            xField="month"
            yField="value"
            height={280}
            axis={{ y: { labelFormatter: usd } }}
            tooltip={{ items: [{ channel: 'y', valueFormatter: usd }] }}
          />
        </Card>
      </Col>
      <Col xs={24} lg={12}>
        <Card title="Joiners and leavers (12 months)">
          <Column data={movementData(points)} xField="month" yField="count" colorField="type" group height={280} />
        </Card>
      </Col>
    </Row>
  )
}
