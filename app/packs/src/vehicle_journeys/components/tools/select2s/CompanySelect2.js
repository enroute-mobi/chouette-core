import React from 'react'
import { Async as Select } from 'react-select'

import { getLineId, getWorkgroupId } from '../../../../helpers/url_params'

const path = `/workgroups/${getWorkgroupId()}/autocomplete/companies`

const CompanySelect2 = ({ company, editMode, editModal, onSelect2Company, onUnselect2Company }) => (
  <Select
    cacheOptions
    isClearable
    defaultValue={company?.id ? { id: company.id, text: company.name } : undefined }
    getOptionLabel={({ text }) => text}
    getOptionValue={({ id }) => id}
    loadOptions={async inputValue => {
      const response = await fetch(`${path}.json?${new URLSearchParams({ line_id: getLineId(), q: inputValue }).toString()}`)
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