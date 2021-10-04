import React from 'react'
import Select from 'react-select'

const VJSelect2 = ({ _isFilter, onSelect2VehicleJourney, options, selectedItem }) => (
  <Select
    options={options}
    getOptionLabel={({ text }) => text}
    getOptionValue={({ id }) => id}
    placeholder={I18n.t('vehicle_journeys.vehicle_journeys_matrix.filters.id')}
    onChange={(selectedItem, meta) => {
      meta.action == 'select-option' && onSelect2VehicleJourney(selectedItem)
    }}
  />
)

export default VJSelect2