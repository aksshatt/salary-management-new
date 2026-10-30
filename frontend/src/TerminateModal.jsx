import { Alert, Form, Input, Modal } from 'antd'
import { apiFetch } from './api.js'
import { showFieldErrors } from './formErrors.js'

export default function TerminateModal({ employee, open, onClose, onTerminated }) {
  const [form] = Form.useForm()

  async function handleFinish({ terminated_on }) {
    try {
      await apiFetch(`/employees/${employee.id}/termination`, { method: 'POST', body: { terminated_on } })
      onTerminated()
    } catch (error) {
      showFieldErrors(form, error)
    }
  }

  return (
    <Modal
      title={`Terminate ${employee.name}`}
      open={open}
      okText="Terminate"
      okButtonProps={{ danger: true }}
      onOk={() => form.submit()}
      onCancel={onClose}
      destroyOnHidden
    >
      <Alert
        type="warning"
        showIcon
        message="This can't be undone."
        description="The last working day can't be changed later. Salary revisions dated after it will never apply."
        style={{ marginBottom: 16 }}
      />
      <Form form={form} layout="vertical" onFinish={handleFinish} requiredMark={false}>
        <Form.Item label="Last working day" name="terminated_on" rules={[{ required: true, message: 'Pick a date' }]}>
          <Input type="date" />
        </Form.Item>
      </Form>
    </Modal>
  )
}
