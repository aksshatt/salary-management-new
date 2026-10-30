import { Alert, Form, InputNumber, Modal } from 'antd'
import { apiFetch } from './api.js'
import { showFieldErrors } from './formErrors.js'

export default function EditRateModal({ rate, onClose, onSaved }) {
  const [form] = Form.useForm()

  async function handleFinish({ units_per_usd }) {
    try {
      await apiFetch(`/exchange_rates/${rate.currency_code}`, { method: 'PATCH', body: { exchange_rate: { units_per_usd } } })
      onSaved()
    } catch (error) {
      showFieldErrors(form, error)
    }
  }

  return (
    <Modal title={`Edit ${rate.currency_code} rate`} open okText="Save" onOk={() => form.submit()} onCancel={onClose}>
      <Alert
        type="info"
        showIcon
        message="All USD figures, including past months on the dashboard, use the current rate."
        style={{ marginBottom: 16 }}
      />
      <Form form={form} layout="vertical" onFinish={handleFinish} initialValues={{ units_per_usd: rate.units_per_usd }}>
        <Form.Item
          label={`${rate.currency_code} per 1 USD`}
          name="units_per_usd"
          rules={[{ required: true, message: 'Enter the rate' }]}
        >
          <InputNumber stringMode min="0.000001" step="0.01" style={{ width: '100%' }} />
        </Form.Item>
      </Form>
    </Modal>
  )
}
