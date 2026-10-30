import { Form, Input, InputNumber, Modal, Select } from 'antd'
import { ApiError, apiFetch } from './api.js'
import { toFieldErrors } from './formErrors.js'

const REASON_OPTIONS = [
  { value: 'increment', label: 'Increment' },
  { value: 'promotion', label: 'Promotion' },
  { value: 'correction', label: 'Correction' },
  { value: 'other', label: 'Other' },
]

export default function AddRevisionModal({ employee, open, onClose, onAdded }) {
  const [form] = Form.useForm()

  async function handleFinish(values) {
    try {
      await apiFetch(`/employees/${employee.id}/salary_revisions`, { method: 'POST', body: { salary_revision: values } })
    } catch (error) {
      if (error instanceof ApiError && error.status === 422) {
        form.setFields(toFieldErrors(error.body.errors))
        return
      }
      throw error
    }
    form.resetFields()
    onAdded()
  }

  return (
    <Modal title="Add salary revision" open={open} okText="Save" onOk={() => form.submit()} onCancel={onClose} destroyOnHidden>
      <Form form={form} layout="vertical" onFinish={handleFinish} requiredMark={false}>
        <Form.Item label="Effective from" name="effective_on" rules={[{ required: true, message: 'Pick a date' }]}>
          <Input type="date" />
        </Form.Item>
        <Form.Item
          label={`Annual salary (${employee.country.currency_code})`}
          name="amount"
          rules={[{ required: true, message: 'Enter the annual salary' }]}
        >
          <InputNumber stringMode min="0.01" step="0.01" style={{ width: '100%' }} />
        </Form.Item>
        <Form.Item label="Reason" name="reason" rules={[{ required: true, message: 'Pick a reason' }]}>
          <Select aria-label="Reason" options={REASON_OPTIONS} />
        </Form.Item>
      </Form>
    </Modal>
  )
}
