import { ApiError } from './api.js'

// The API returns { field: [messages] }; Ant Design's form.setFields wants a list.
export function toFieldErrors(errors) {
  return Object.entries(errors).map(([name, messages]) => ({ name, errors: messages }))
}

// Shows a 422 response's errors on the form; any other error is rethrown.
export function showFieldErrors(form, error) {
  if (!(error instanceof ApiError && error.status === 422)) throw error
  form.setFields(toFieldErrors(error.body.errors))
}
