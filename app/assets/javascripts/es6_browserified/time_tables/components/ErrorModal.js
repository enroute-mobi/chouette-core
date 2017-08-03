var React = require('react')
var Component = require('react').Component
var PropTypes = require('react').PropTypes

const ErrorModal = ({dispatch, modal, onModalClose}) => (
  <div className={ 'modal fade ' + ((modal.type == 'error') ? 'in' : '') } id='ErrorModal'>
    <div className='modal-container'>
      <div className='modal-dialog'>
        <div className='modal-content'>
          <div className='modal-header'>
            <h4 className='modal-title'>{window.I18n.fr.time_tables.edit.error_modal.title}</h4>
          </div>
          <div className='modal-body'>
            <div className='mt-md mb-md'>
              <p>{(modal.modalProps.error == "withoutPeriodsWithDaysTypes") ? window.I18n.fr.time_tables.edit.error_modal.withoutPeriodsWithDaysTypes : window.I18n.fr.time_tables.edit.error_modal.withPeriodsWithoutDayTypes}</p>
            </div>
          </div>
          <div className='modal-footer'>
            <button
              className='btn btn-link'
              data-dismiss='modal'
              type='button'
              onClick= {() => {onModalClose()}}
              >
              Retour
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
)

ErrorModal.propTypes = {
  modal: PropTypes.object.isRequired,
  onModalClose: PropTypes.func.isRequired
}

module.exports = ErrorModal
