import { Alert, Form, Input, Modal } from 'antd'
import { apiFetch } from './api.js'
import { showFieldErrors } from './formErrors.js'

export default function EditTaxRateModal({ country, onClose, onSaved }) {
  const [form] = Form.useForm()

  async function handleFinish({ tax_rate_percent }) {
    try {
      await apiFetch(`/countries/${country.id}`, { method: 'PATCH', body: { country: { tax_rate_percent } } })
      onSaved()
    } catch (error) {
      showFieldErrors(form, error)
    }
  }

  return (
    <Modal title={`Edit ${country.name} tax rate`} open okText="Save" onOk={() => form.submit()} onCancel={onClose}>
      <Alert
        type="info"
        showIcon
        message="A new rate reaches the open payroll month when it is recalculated. Locked months keep the rate they used."
        style={{ marginBottom: 16 }}
      />
      <Form form={form} layout="vertical" onFinish={handleFinish} initialValues={{ tax_rate_percent: country.tax_rate_percent }}>
        <Form.Item label="Tax rate (%)" name="tax_rate_percent" rules={[{ required: true, message: 'Enter the tax rate' }]}>
          <Input inputMode="decimal" suffix="%" />
        </Form.Item>
      </Form>
    </Modal>
  )
}
