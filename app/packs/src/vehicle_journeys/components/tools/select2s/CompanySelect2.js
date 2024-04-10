import React from 'react'
import { Async as Select } from 'react-select'
import { Path } from 'path-parser'

const params = new Path('/workbenches/:workbenchId/referentials/:referentialId/lines/:lineId/routes/:routeId').partialTest(location.pathname)
const comapniesPathParams = new Path('/workbenches/:workbenchId/line_referential/companies').partialTest(window.companiesPath || '') // Doing for to let specs pass (could not find a wat to mock window values properly)

const path = `/workbenches/${comapniesPathParams?.workbenchId}/autocomplete/companies`

const CompanySelect2 = ({ company, editMode, editModal, onSelect2Company, onUnselect2Company }) => (
  <Select
    cacheOptions
    isClearable
    defaultOptions
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
    onChange={(company, meta) => {
      switch(meta.action) {
        case 'select-option':
          onSelect2Company({ id: company.id, name: company.text })
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
