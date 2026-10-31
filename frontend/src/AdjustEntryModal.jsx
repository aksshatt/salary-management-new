import { Form, Input, Modal } from 'antd'
import { apiFetch } from './api.js'
import { showFieldErrors } from './formErrors.js'

// One-time bonus, deduction and note for an entry in the open month.
export default function AdjustEntryModal({ month, entry, onClose, onSaved }) {
  const [form] = Form.useForm()
  const currency = entry.currency_code

  async function handleFinish(values) {
    try {
      await apiFetch(`/payroll_runs/${month}/entries/${entry.id}`, { method: 'PATCH', body: { payroll_entry: values } })
      onSaved()
    } catch (error) {
      showFieldErrors(form, error)
    }
  }

  return (
    <Modal title={`Adjust ${entry.name}`} open okText="Save" onOk={() => form.submit()} onCancel={onClose}>
      <Form
        form={form}
        layout="vertical"
        onFinish={handleFinish}
        initialValues={{ bonus: entry.bonus, deduction: entry.deduction, note: entry.note ?? '' }}
      >
        <Form.Item label={`Bonus (${currency})`} name="bonus" extra="Taxed with this month's gross.">
          <Input inputMode="decimal" />
        </Form.Item>
        <Form.Item label={`Deduction (${currency})`} name="deduction" extra="Taken after tax, e.g. to recover a loan.">
          <Input inputMode="decimal" />
        </Form.Item>
        <Form.Item label="Note" name="note">
          <Input.TextArea maxLength={500} rows={2} />
        </Form.Item>
      </Form>
    </Modal>
  )
}
