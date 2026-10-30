import { Alert, Card, Col, Input, Radio, Row, Space, Spin, Statistic, Typography } from 'antd'
import { lazy, Suspense, useEffect, useState } from 'react'
import { useLocation, useNavigate } from 'react-router'
import { apiFetch } from './api.js'
import { donutData } from './chartData.js'
import EmployeeFilters from './EmployeeFilters.jsx'
import { formatMoney } from './format.js'
import { insightsQueryString, parseInsightsQuery } from './insightsQuery.js'

const CostDonut = lazy(() => import('./CostDonut.jsx'))
const TrendCharts = lazy(() => import('./TrendCharts.jsx'))

const usd = (amount) => formatMoney(amount === null ? null : { amount, currency_code: 'USD' })

const TILES = [
  ['Headcount', (stats) => String(stats.headcount)],
  ['Annual salary cost', (stats) => usd(stats.annual_cost)],
  ['Monthly salary cost', (stats) => usd(stats.monthly_cost)],
  ['Average salary', (stats) => usd(stats.average)],
  ['Median salary', (stats) => usd(stats.median)],
  ['Lowest salary', (stats) => usd(stats.lowest)],
  ['Highest salary', (stats) => usd(stats.highest)],
]

export default function DashboardPage() {
  const location = useLocation()
  const navigate = useNavigate()
  const query = parseInsightsQuery(location.search)
  const queryString = insightsQueryString(query)
  const [insights, setInsights] = useState(null)
  const [error, setError] = useState(null)
  const [trends, setTrends] = useState(null)
  // Trends don't depend on the donut grouping, so switching it doesn't refetch them.
  const trendsQueryString = insightsQueryString({ ...query, group_by: 'country' })

  useEffect(() => {
    apiFetch(`/insights/trends${trendsQueryString}`)
      .then(setTrends)
      .catch(() => setTrends(null))
  }, [trendsQueryString])
  const [options, setOptions] = useState({ countries: [], departments: [], job_titles: [] })

  useEffect(() => {
    apiFetch('/filter_options').then(setOptions)
  }, [])

  useEffect(() => {
    apiFetch(`/insights${queryString}`)
      .then((data) => {
        setInsights(data)
        setError(null)
      })
      .catch((e) => setError(e.message))
  }, [queryString])

  function updateQuery(changes) {
    navigate(`/${insightsQueryString({ ...query, ...changes })}`)
  }

  if (error) return <Alert type="error" showIcon message={error} />
  if (!insights) return <Spin />

  return (
    <>
      <Typography.Title level={3}>Pay insights</Typography.Title>
      <Space wrap style={{ marginBottom: 16 }}>
        <Input
          type="month"
          aria-label="Month"
          value={insights.month}
          onChange={(event) => updateQuery({ month: event.target.value })}
          style={{ width: 170 }}
        />
        <EmployeeFilters options={options} query={query} onChange={updateQuery} />
      </Space>
      <Typography.Paragraph type="secondary">As of {insights.as_of}</Typography.Paragraph>
      {insights.stats.without_salary > 0 && (
        <Alert
          type="warning"
          showIcon
          style={{ marginBottom: 16 }}
          message={`Left out of the salary figures (no salary in USD): ${insights.stats.without_salary}`}
        />
      )}
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        {TILES.map(([title, value]) => (
          <Col key={title} xs={12} md={6}>
            <Card size="small">
              <Statistic title={title} valueRender={() => value(insights.stats)} />
            </Card>
          </Col>
        ))}
      </Row>
      <Card
        title={`Annual cost by ${insights.breakdown.group_by}`}
        extra={
          <Radio.Group
            value={query.group_by}
            onChange={(event) => updateQuery({ group_by: event.target.value })}
            options={[
              { value: 'country', label: 'By country' },
              { value: 'department', label: 'By department' },
            ]}
            optionType="button"
          />
        }
      >
        <Suspense fallback={<Spin />}>
          <CostDonut data={donutData(insights.breakdown.groups)} />
        </Suspense>
      </Card>
      {trends && (
        <div style={{ marginTop: 16 }}>
          <Suspense fallback={<Spin />}>
            <TrendCharts points={trends.points} />
          </Suspense>
        </div>
      )}
    </>
  )
}
