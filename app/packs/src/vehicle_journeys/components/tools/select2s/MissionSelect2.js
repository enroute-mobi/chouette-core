import React from 'react'
import { Async as Select } from 'react-select'

import { getReferentialId, getRouteId } from '../../../../helpers/url_params'

const path = `/referentials/${getReferentialId()}/autocomplete/journey_patterns`

const JPSelect2 = ({ isFilter, onSelect2JourneyPattern, selectedItem }) =>  (
  <Select
    defaultValue={(isFilter && selectedItem?.id) ? { id: selectedItem.id, text: selectedItem.published_name } : undefined}
    className={isFilter ? null : 'vjCreateSelectJP'}
    cacheOptions
    defaultOptions
    formatOptionLabel={(option, _meta) => <div dangerouslySetInnerHTML={{ __html: option.text }} />}
    getOptionLabel={({ text }) => text}
    getOptionValue={({ id }) => id}
    placeholder={I18n.t('vehicle_journeys.vehicle_journeys_matrix.filters.journey_pattern')}
    loadOptions={async inputValue => {
      const queryParams = new URLSearchParams({ route_id: getRouteId(), q: inputValue })
      const response = await fetch(`${path}.json?${queryParams.toString()}`)
      const journeyPatterns = await response.json()

      return journeyPatterns
    }}
    onChange={(selectedItem, meta) => {
      meta.action == 'select-option' && onSelect2JourneyPattern(selectedItem)
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

export default JPSelect2
