import React from 'react'
import PropTypes from 'prop-types'

export default function CopyButton({ onClick, disabled }) {
  return (
    <li className='st_action'>
      <button
        type='button'
        disabled={ disabled }
        title={ I18n.t('actions.copy') }
        onClick={e => {
          e.preventDefault()
          onClick()
        }}
      >
        <span className='fa fa-copy'></span>
      </button>
    </li>
  )
}

CopyButton.propTypes = {
  onClick: PropTypes.func.isRequired,
  disabled: PropTypes.bool.isRequired,
  selectionMode: PropTypes.bool.isRequired
}
