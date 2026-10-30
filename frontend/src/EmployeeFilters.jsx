import { Select } from 'antd'

// Country, department and job title dropdowns, shared by the employee list
// and the dashboard. Clearing one sends an empty value.
export default function EmployeeFilters({ options, query, onChange }) {
  const select = (label, key, items, width) => (
    <Select
      aria-label={label}
      placeholder={label}
      allowClear
      value={query[key] || undefined}
      options={items}
      onChange={(value) => onChange({ [key]: value ?? '' })}
      style={{ width }}
    />
  )

  return (
    <>
      {select('Country', 'country_id', options.countries.map((c) => ({ value: String(c.id), label: c.name })), 180)}
      {select('Department', 'department', options.departments.map((d) => ({ value: d, label: d })), 180)}
      {select('Job title', 'job_title', options.job_titles.map((t) => ({ value: t, label: t })), 220)}
    </>
  )
}
