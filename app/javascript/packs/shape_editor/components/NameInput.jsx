import React from 'react'
import PropTypes from 'prop-types'

import store from '../shape.store'

const NameInput = ({ name }) => (
  <>
    <label htmlFor="name">{I18n.t('activerecord.attributes.shape.name')} :</label>
    <input
      id="name"
      onChange={e => store.setAttributes({ name: e.target.value })}
      value={name}
    />
  </>
)

NameInput.propTypes = {
  name: PropTypes.string.isRequired
}

export default NameInput