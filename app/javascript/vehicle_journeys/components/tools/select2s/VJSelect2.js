import React from 'react'
import Select from 'react-select'

const VJSelect2 = ({ _isFilter, onSelect2VehicleJourney, options, selectedItem }) => (
  <Select
    options={options}
    getOptionLabel={({ text }) => text}
    getOptionValue={({ id }) => id}
    formatOptionLabel={(option, _meta) => <div dangerouslySetInnerHTML={{ __html: option.text }} />}
    searchField={['short_id', 'published_journey_name']}
    placeholder={I18n.t('vehicle_journeys.vehicle_journeys_matrix.filters.id')}
    onChange={(selectedItem, meta) => {
      meta.action == 'select-option' && onSelect2VehicleJourney(selectedItem)
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

export default VJSelect2