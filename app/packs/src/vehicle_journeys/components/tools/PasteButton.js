import React from 'react'
import PropTypes from 'prop-types'

import actions from '../../actions'

export default function PasteButton({onClick, disabled, selectionMode}) {
  return (
    <li className='st_action'>
      <button
        type='button'
        disabled={ disabled }
        title={ I18n.t('actions.paste') }
        onClick={e => {
          e.preventDefault()
          onClick()
        }}
      >
        <span className='fa fa-paste'></span>
      </button>
    </li>
  )
}

PasteButton.propTypes = {
  onClick: PropTypes.func.isRequired,
  disabled: PropTypes.bool.isRequired,
  selectionMode: PropTypes.bool.isRequired
}
