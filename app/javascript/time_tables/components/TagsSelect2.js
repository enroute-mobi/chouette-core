import React, { Component } from 'react'
import PropTypes from 'prop-types'
import Select2 from 'react-select/lib/Creatable'
import createSelect2 from '../../helpers/select2/select2';

function TagsSelect2(props) {
  return (
    <Select2
      name='tags_id'
      isMulti
      isClearable
      placeholder={I18n.t('time_tables.edit.select2.tag.placeholder')}
      noOptionsMessage={() => I18n.t('time_tables.edit.select2.tag.no_options')}
      formatCreateLabel={() => I18n.t('time_tables.edit.select2.tag.create_tag_label', {tag: props.inputValue})}
      {...props}
    />
  )
}

TagsSelect2.propTypes = {
  inputValue: PropTypes.string.isRequired,
  options: PropTypes.array.isRequired,
  onChange: PropTypes.func.isRequired,
  onInputChange: PropTypes.func.isRequired
}

export default createSelect2(TagsSelect2)
