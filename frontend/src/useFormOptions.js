import { useEffect, useState } from 'react'
import { apiFetch } from './api.js'

const NO_OPTIONS = { countries: [], departments: [], job_titles: [] }

// Choices for the add/edit employee forms: every country (even one with no
// employees yet) and, as suggestions, the departments and job titles in use.
export function useFormOptions(open) {
  const [options, setOptions] = useState(NO_OPTIONS)

  useEffect(() => {
    if (!open) return
    Promise.all([apiFetch('/countries'), apiFetch('/filter_options')]).then(([countryData, filterData]) =>
      setOptions({ countries: countryData.countries, departments: filterData.departments, job_titles: filterData.job_titles }),
    )
  }, [open])

  return options
}
