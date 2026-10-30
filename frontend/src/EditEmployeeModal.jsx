import { Alert, Form, Modal } from 'antd'
import { useEffect, useState } from 'react'
import { apiFetch } from './api.js'
import { employeeUpdatePayload } from './employeePayload.js'
import EmployeeFormFields from './EmployeeFormFields.jsx'
import { showFieldErrors } from './formErrors.js'

const NO_OPTIONS = { countries: [], departments: [], job_titles: [] }

export default function EditEmployeeModal({ employee, open, onClose, onSaved }) {
  const [form] = Form.useForm()
  const [options, setOptions] = useState(NO_OPTIONS)
  const countryId = Form.useWatch('country_id', form)
  const newCurrency = options.countries.find((country) => String(country.id) === countryId)?.currency_code
  const currentCurrency = employee.country.currency_code

  useEffect(() => {
    if (open) apiFetch('/filter_options').then(setOptions)
  }, [open])

  async function handleFinish(values) {
    // The join date is shown for reference only and can't be changed.
    const { joined_on: _joinedOn, ...editable } = values
    try {
      await apiFetch(`/employees/${employee.id}`, { method: 'PATCH', body: employeeUpdatePayload(editable) })
      onSaved()
    } catch (error) {
      showFieldErrors(form, error)
    }
  }

  return (
    <Modal title="Edit employee" open={open} okText="Save" onOk={() => form.submit()} onCancel={onClose} destroyOnHidden>
      <Form
        form={form}
        layout="vertical"
        onFinish={handleFinish}
        requiredMark={false}
        initialValues={{
          name: employee.name,
          email: employee.email,
          country_id: String(employee.country.id),
          department: employee.department,
          job_title: employee.job_title,
          joined_on: employee.joined_on,
          bank_account_number: '',
        }}
      >
        <EmployeeFormFields options={options} editing />
        {newCurrency && newCurrency !== currentCurrency && (
          <Alert
            type="warning"
            showIcon
            message={`New salary revisions will be in ${newCurrency}. Existing salaries stay in ${currentCurrency}.`}
          />
        )}
      </Form>
    </Modal>
  )
}
