import React, { Component } from 'react'
import PropTypes from 'prop-types'

export default class CancelButton extends Component {
  constructor(props) {
    super(props)
  }

  btnDisabled() {
    return !this.props.status.fetchSuccess || this.props.status.isFetching || (this.props.editMode == false)
  }

  btnClass() {
    let className = ['btn btn-cancel']
    if (this.btnDisabled()) {
      className.push('disabled')
    }
    return className.join(' ')
  }

  hasPolicy() {
    return true
  }

  render() {
    if (!this.hasPolicy()) {
      return false
    }
    return (
      <div className='row mt-md'>
        <div className='col-lg-12 text-right'>
          <form className={this.formClassName() + ' formSubmitr ml-xs'} onSubmit={e => { e.preventDefault() }}>
            <div className="btn-group sticky-actions">
              <button
                className={this.btnClass()}
                type='button'
                disabled={this.btnDisabled()}
                onClick={e => {
                  e.preventDefault()
                  $('#CancelButtonModal').modal('show')
                }}
              >
                {I18n.t('cancel')}
              </button>
            </div>
          </form>
        </div>
        <div className="modal fade" id="CancelButtonModal" tabIndex="1" role="dialog">
          < div className="modal-container" >
            <div className="modal-dialog">
              <div className="modal-content">
                <div className="modal-header">
                  <h4 className="modal-title"> {I18n.t('warning')} </h4>
                </div>
                <div className="modal-body">
                  <p>{I18n.t('cancel_confirm')}</p>
                </div>
                <div className="modal-footer">
                  <a data-dismiss="modal" className="btn btn-cancel">{I18n.t('no')}</a>
                  <a data-dismiss="modal" className="btn btn-default" data-method="get" onClick={this.props.onConfirmCancel}>{I18n.t('yes')}</a>
                </div>
              </div>
            </div>
          </div >
        </div >
      </div>
    )
  }
}

CancelButton.propTypes = {
  onConfirmCancel: PropTypes.func.isRequired
}

CancelButton.defaultProps = {
  status: {
    fetchSuccess: false,
    isFetching: false
  }
}