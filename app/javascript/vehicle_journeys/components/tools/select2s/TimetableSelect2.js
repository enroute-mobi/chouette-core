import React from 'react'
import { Async as Select } from 'react-select'

import { getReferentialId, getRouteId } from '../../../../helpers/url_params'

const path = `/referentials/${getReferentialId()}/autocomplete/time_tables`

const TTSelect2 = ({ isFilter, onSelect2Timetable, selectedItem }) => (
  <Select
    defaultValue={(isFilter && selectedItem?.id) ? { id: selectedItem.id, text: selectedItem.comment } : undefined}
    cacheOptions
    defaultOptions
    formatOptionLabel={(option, _meta) => <div dangerouslySetInnerHTML={{ __html: option.text }} />}
    getOptionLabel={({ text }) => text}
    getOptionValue={({ id }) => id}
    placeholder={I18n.t('vehicle_journeys.vehicle_journeys_matrix.filters.timetable')}
    loadOptions={async inputValue => {
      const queryParams = new URLSearchParams({ q: inputValue })
      isFilter && queryParams.set('route_id', getRouteId())
      const response = await fetch(`${path}.json?${queryParams.toString()}`)
      const timeTables = await response.json()

      return timeTables
    }}
    onChange={(selectedItem, meta) => {
      meta.action == 'select-option' && onSelect2Timetable(selectedItem)
    }}
    styles={{
      control: (provided) => ({
        ...provided,
        minHeight: '51px',
        height: '51px'
      }),
    }}
  />
)

export default TTSelect2