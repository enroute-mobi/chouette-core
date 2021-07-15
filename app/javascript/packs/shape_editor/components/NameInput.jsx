import React from 'react'

import store from '../shape.store'

const Name = ({ name }) => (
  <>
    <label htmlFor="name">{I18n.t('activerecord.attributes.shape.name')} :</label>
    <input
      id="name"
      onChange={e => store.setAttributes({ name: e.target.value })}
      value={name}
    />
  </>
)
export default Name