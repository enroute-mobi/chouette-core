import React from 'react'
import { Async as Select } from 'react-select'

const ShapeSelect2 = ({ disabled, onSelectShape, onUnselectShape, shape }) => (
  <Select
    isClearable
    disabled={disabled}
    defaultValue={shape ? { id: shape.id, text: (shape.name || shape.uuid) } : undefined}
    cacheOptions
    defaultOptions
    formatOptionLabel={(option, _meta) => <div dangerouslySetInnerHTML={{ __html: option.text }} />}
    getOptionLabel={({ text }) => text}
    getOptionValue={({ id }) => id}
    placeholder={I18n.t('journey_patterns.form.shape_placeholder')}
    loadOptions={async inputValue => {
      const response = await fetch(`${window.shapes_url}?${new URLSearchParams({ q: inputValue }).toString()}`)
      return await response.json()
    }}
    onChange={(selectedItem, meta) => {
      switch(meta.action) {
        case 'select-option':
          onSelectShape(selectedItem)
          break
        case 'deselect-option':
        case 'clear':
          onUnselectShape()
          break
      }
    }}
  />
)

export default ShapeSelect2