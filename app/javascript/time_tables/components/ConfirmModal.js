import React from 'react'
import PropTypes from 'prop-types'


export default function ConfirmModal({dispatch, modal, onModalAccept, onModalCancel, timetable, metas}, {I18n}) {
  return (
    <div className={'modal fade ' + ((modal.type == 'confirm') ? 'in' : '')} id='ConfirmModal'>
      <div className='modal-container'>
        <div className='modal-dialog'>
          <div className='modal-content'>
            <div className='modal-header'>
              <h4 className='modal-title'>{I18n.t('time_tables.edit.confirm_modal.title')}</h4>
            </div>
            <div className='modal-body'>
              <div className='mt-md mb-md'>
                <p>{I18n.t('time_tables.edit.confirm_modal.message')}</p>
              </div>
            </div>
            <div className='modal-footer'>
              <button
                className='btn btn-link'
                data-dismiss='modal'
                type='button'
                onClick={() => { onModalCancel(modal.confirmModal.callback) }}
              >
                {I18n.t('cancel')}
              </button>
              <button
                className='btn btn-primary'
                data-dismiss='modal'
                type='button'
                onClick={() => { onModalAccept(modal.confirmModal.callback, timetable, metas) }}
              >
                {I18n.t('actions.submit')}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

ConfirmModal.propTypes = {
  modal: PropTypes.object.isRequired,
  onModalAccept: PropTypes.func.isRequired,
  onModalCancel: PropTypes.func.isRequired
}

ConfirmModal.contextTypes = {
  I18n: PropTypes.object
}
