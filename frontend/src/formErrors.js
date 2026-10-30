// The API returns { field: [messages] }; Ant Design's form.setFields wants a list.
export function toFieldErrors(errors) {
  return Object.entries(errors).map(([name, messages]) => ({ name, errors: messages }))
}
