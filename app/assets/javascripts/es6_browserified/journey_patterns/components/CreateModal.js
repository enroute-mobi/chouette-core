var React = require('react')
var Component = require('react').Component
var PropTypes = require('react').PropTypes
var actions = require('../actions')

class CreateModal extends Component {
  constructor(props) {
    super(props)
  }

  handleSubmit() {
    if(actions.validateFields(this.refs) == true) {
      this.props.onAddJourneyPattern(this.refs)
      this.props.onModalClose()
      $('#NewJourneyPatternModal').modal('hide')
    }
  }

  render() {
    if(this.props.status.isFetching == true || this.props.status.policy['journey_patterns.create'] == false || this.props.editMode == false) {
      return false
    }
    if(this.props.status.fetchSuccess == true) {
      return (
        <div className="select_toolbox">
          <ul>
            <li className='st_action'>
              <button
                type='button'
                data-toggle='modal'
                data-target='#NewJourneyPatternModal'
                onClick={this.props.onOpenCreateModal}
                >
                <span className="fa fa-plus"></span>
              </button>

              <div className={ 'modal fade ' + ((this.props.modal.type == 'create') ? 'in' : '') } id='NewJourneyPatternModal'>
                <div className='modal-container'>
                  <div className='modal-dialog'>
                    <div className='modal-content'>
                      <div className='modal-header'>
                        <h4 className='modal-title'>Ajouter une mission</h4>
                      </div>

                      {(this.props.modal.type == 'create') && (
                        <form>
                          <div className='modal-body'>
                            <div className='form-group'>
                              <label className='control-label is-required'>Nom</label>
                              <input
                                type='text'
                                ref='name'
                                className='form-control'
                                onKeyDown={(e) => actions.resetValidation(e.currentTarget)}
                                required
                                />
                            </div>
                            <div className='row'>
                              <div className='col-lg-6 col-md-6 col-sm-6 col-xs-6'>
                                <div className='form-group'>
                                  <label className='control-label is-required'>Nom public</label>
                                  <input
                                    type='text'
                                    ref='published_name'
                                    className='form-control'
                                    onKeyDown={(e) => actions.resetValidation(e.currentTarget)}
                                    required
                                    />
                                </div>
                              </div>
                              <div className='col-lg-6 col-md-6 col-sm-6 col-xs-6'>
                                <div className='form-group'>
                                  <label className='control-label'>Code mission</label>
                                  <input
                                    type='text'
                                    ref='registration_number'
                                    className='form-control'
                                    onKeyDown={(e) => actions.resetValidation(e.currentTarget)}
                                    />
                                </div>
                              </div>
                            </div>
                          </div>
                          <div className='modal-footer'>
                            <button
                              className='btn btn-link'
                              data-dismiss='modal'
                              type='button'
                              onClick={this.props.onModalClose}
                              >
                              Annuler
                            </button>
                            <button
                              className='btn btn-primary'
                              type='button'
                              onClick={this.handleSubmit.bind(this)}
                              >
                              Valider
                            </button>
                          </div>
                        </form>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            </li>
          </ul>
        </div>
      )
    } else {
      return false
    }
  }
}

CreateModal.propTypes = {
  index: PropTypes.number,
  modal: PropTypes.object.isRequired,
  status: PropTypes.object.isRequired,
  onOpenCreateModal: PropTypes.func.isRequired,
  onModalClose: PropTypes.func.isRequired,
  onAddJourneyPattern: PropTypes.func.isRequired
}

module.exports = CreateModal
