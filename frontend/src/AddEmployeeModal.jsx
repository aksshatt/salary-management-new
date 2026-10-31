import { Form, InputNumber, Modal } from 'antd'
import { apiFetch } from './api.js'
import EmployeeFormFields from './EmployeeFormFields.jsx'
import { showFieldErrors } from './formErrors.js'
import { useFormOptions } from './useFormOptions.js'

export default function AddEmployeeModal({ open, onClose, onAdded }) {
  const [form] = Form.useForm()
  const options = useFormOptions(open)
  const countryId = Form.useWatch('country_id', form)
  const currency = options.countries.find((country) => String(country.id) === countryId)?.currency_code

  async function handleFinish({ initial_salary, ...employee }) {
    try {
      const data = await apiFetch('/employees', { method: 'POST', body: { employee, initial_salary } })
      onAdded(data.employee)
    } catch (error) {
      showFieldErrors(form, error)
    }
  }

  return (
    <Modal title="Add employee" open={open} okText="Add" onOk={() => form.submit()} onCancel={onClose} destroyOnHidden>
      <Form form={form} layout="vertical" onFinish={handleFinish} requiredMark={false}>
        <EmployeeFormFields options={options} />
        <Form.Item
          label={currency ? `Initial annual salary (${currency})` : 'Initial annual salary'}
          name="initial_salary"
          rules={[{ required: true, message: 'Enter the initial salary' }]}
        >
          <InputNumber stringMode min="0.01" step="0.01" style={{ width: '100%' }} />
        </Form.Item>
      </Form>
    </Modal>
  )
}
