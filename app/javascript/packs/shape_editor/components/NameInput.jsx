import React from 'react'
import PropTypes from 'prop-types'

import store from '../shape.store'

const NameInput = ({ name = '' }) => (
  <div className="form-group">
    <label className="col-sm-4 col-xs-5 control-label string required" htmlFor="name">{I18n.t('activerecord.attributes.shape.name')} :</label>
    <div className="col-sm-8 col-xs-7">
    <input
      id="name"
      className="form-control string required"
      onChange={e => store.updateName({ name: e.target.value })}
      value={name}
    />
    </div>
  </div>
)

NameInput.propTypes = {
  name: PropTypes.string
}

export default NameInput
