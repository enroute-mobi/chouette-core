import React from 'react'
import { Async as Select } from 'react-select'
import { Path } from 'path-parser'

const params = new Path('/referentials/:referentialId/lines/:lineId/routes/:routeId').partialTest(location.pathname)

const path = `/workbenches/${window.workbench_id}/autocomplete/companies`

const CompanySelect2 = ({ company, editMode, editModal, onSelect2Company, onUnselect2Company }) => (
  <Select
    cacheOptions
    isClearable
    defaultValue={company?.id ? { id: company.id, text: company.name } : undefined }
    getOptionLabel={({ text }) => text}
    getOptionValue={({ id }) => id}
    loadOptions={async inputValue => {
      const response = await fetch(`${path}.json?${new URLSearchParams({ line_id: params?.lineId, q: inputValue }).toString()}`)
      const companies = await response.json()

      return companies
    }}
    isDisabled={!editMode && editModal}
    placeholder={I18n.t('vehicle_journeys.vehicle_journeys_matrix.affect_company')}
    onChange={(selectIem, meta) => {
      switch(meta.action) {
        case 'select-option':
          onSelect2Company(selectIem)
          break
        case 'deselect-option':
        case 'clear':
          onUnselect2Company()
          break
      }
    }}
    styles={{
      control: (provided) => ({
        ...provided,
        minHeight: '51px',
        height: '51px'
      }),
      menu: base => ({ ...base, zIndex: 2000 })
    }}
  />
)

export default CompanySelect2
