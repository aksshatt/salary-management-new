import { AutoComplete, Form, Input, Select } from 'antd'

// Fields shared by the add and edit employee dialogs. Department and job
// title are free text, with the values already in use as suggestions.
export default function EmployeeFormFields({ options, editing = false }) {
  const required = (message) => [{ required: true, message }]
  const suggestions = (values) => values.map((value) => ({ value }))

  return (
    <>
      <Form.Item label="Name" name="name" rules={required('Enter the name')}>
        <Input />
      </Form.Item>
      <Form.Item label="Email" name="email" rules={required('Enter the email')}>
        <Input type="email" />
      </Form.Item>
      <Form.Item label="Country" name="country_id" rules={required('Pick a country')}>
        <Select
          aria-label="Country"
          options={options.countries.map((country) => ({ value: String(country.id), label: country.name }))}
        />
      </Form.Item>
      <Form.Item label="Department" name="department" rules={required('Enter the department')}>
        <AutoComplete options={suggestions(options.departments)} filterOption />
      </Form.Item>
      <Form.Item label="Job title" name="job_title" rules={required('Enter the job title')}>
        <AutoComplete options={suggestions(options.job_titles)} filterOption />
      </Form.Item>
      <Form.Item label="Join date" name="joined_on" rules={required('Pick the join date')}>
        <Input type="date" disabled={editing} />
      </Form.Item>
      <Form.Item label="Bank account number" name="bank_account_number" rules={editing ? [] : required('Enter the bank account number')}>
        <Input autoComplete="off" />
      </Form.Item>
    </>
  )
}
