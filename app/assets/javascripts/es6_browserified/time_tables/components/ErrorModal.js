var React = require('react')
var Component = require('react').Component
var PropTypes = require('react').PropTypes

const withoutPeriodsWithDaysTypes = "Un calendrier d'application ne peut pas avoir de journée(s) d'application sans période(s)."
const withPeriodsWithoutDayTypes = "Un calendrier d'application ne peut pas avoir de période(s) sans journée(s) d'application."


const ErrorModal = ({dispatch, modal, onModalClose}) => (
  <div className={ 'modal fade ' + ((modal.type == 'error') ? 'in' : '') } id='ErrorModal'>
    <div className='modal-container'>
      <div className='modal-dialog'>
        <div className='modal-content'>
          <div className='modal-header'>
            <h4 className='modal-title'>Erreur</h4>
          </div>
          <div className='modal-body'>
            <div className='mt-md mb-md'>
              <p>{(modal.modalProps.error == "withoutPeriodsWithDaysTypes") ? withoutPeriodsWithDaysTypes : withPeriodsWithoutDayTypes}</p>
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
