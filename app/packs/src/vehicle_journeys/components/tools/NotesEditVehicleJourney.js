import React, { Component } from 'react'
import PropTypes from 'prop-types'
import actions from '../../actions'
import _ from 'lodash'

export default class NotesEditVehicleJourney extends Component {
  constructor(props) {
    super(props)
  }

  handleSubmit() {
    this.props.onNotesEditVehicleJourney(this.props.modal.modalProps.vehicleJourney.footnotes, this.props.modal.modalProps.vehicleJourney.line_notices)
    this.props.onModalClose()
    $('#NotesEditVehicleJourneyModal').modal('hide')
  }

  footnotes() {
    let { footnotes, line_notices } = this.props.modal.modalProps.vehicleJourney
    let fnIds = footnotes.map(fn => fn.id)
    let lnIds = line_notices.map(fn => fn.id)
    return {
      associated: footnotes.concat(line_notices),
      to_associate: window.line_footnotes.filter(fn => {
        if(fn.line_notice){
          return !lnIds.includes(fn.id)
        }
        else{
          return !fnIds.includes(fn.id)
        }
      })
    }
  }

  renderFootnoteButton(lf) {
    if (!this.props.editMode) return false

    if (this.footnotes().associated.includes(lf)) {
      return <button
        type='button'
        className='btn btn-outline-danger btn-xs'
        onClick={() => this.props.onToggleFootnoteModal(lf, false)}
      ><span className="fa fa-trash"></span>{I18n.t('actions.remove')}</button>
    } else {
      return <button
        type='button'
        className='btn btn-primary btn-xs'
        onClick={() => this.props.onToggleFootnoteModal(lf, true)}
      ><span className="fa fa-plus"></span>{I18n.t('actions.add')}</button>
    }
  }

  noteUrl(lf) {
    if(lf.line_notice){
      return window.default_line_notices_path + "/" + lf.id
    }
    else {
      return "/workbenches/" + window.workbench_id + "/referentials/" + window.referential_id + "/lines/" + window.line_id + "/footnotes"
    }
  }

  renderAssociatedFN() {
    if (this.footnotes().associated.length == 0) {
      return <h3>{I18n.t('vehicle_journeys.vehicle_journeys_matrix.no_associated_footnotes')}</h3>
    } else {
      return (
        <div>
          <h3>{I18n.t('vehicle_journeys.form.footnotes')} :</h3>
          {this.footnotes().associated.map((lf, i) =>
            <div
              key={i}
              className='panel panel-default'
            >
              <div className='panel-heading'>
                <h4 className='panel-title clearfix'>
                  <a href={ this.noteUrl(lf) }>
                    <div className='pull-left' style={{ paddingTop: '3px' }}>
                    {lf.code}</div>
                    {
                      lf.line_notice &&
                      <div className='pull-left'>{'\u00A0'}<span className='badge badge-info'>{I18n.t('activerecord.models.line_notice.one')}</span></div>
                    }
                  </a>
                  <div className='pull-right'>{this.renderFootnoteButton(lf)}</div>
                </h4>
              </div>
              <div className='panel-body'><p>{lf.label}</p></div>
            </div>
          )}
        </div>
      )
    }
  }

  renderToAssociateFN() {
    if (window.line_footnotes.length == 0) return <h3>{I18n.t('vehicle_journeys.vehicle_journeys_matrix.no_line_footnotes')}</h3>

    if (this.footnotes().to_associate.length == 0) return false

    return (
      <div>
        <h3 className='mt-lg'>{I18n.t('vehicle_journeys.vehicle_journeys_matrix.select_footnotes')} :</h3>
        {this.footnotes().to_associate.map((lf, i) =>
          <div key={i} className='panel panel-default'>
            <div className='panel-heading'>
              <h4 className='panel-title clearfix'>
                <div className='pull-left' style={{ paddingTop: '3px' }}>{lf.code}</div>
                <div className='pull-right'>{this.renderFootnoteButton(lf)}</div>
              </h4>
            </div>
            <div className='panel-body'><p>{lf.label}</p></div>
          </div>
        )}
      </div>
    )
  }

  render() {
    if (this.props.status.isFetching == true) return false

    if (this.props.status.fetchSuccess == true) {
      return (
        <li className='st_action'>
          <button
            type='button'
            disabled={(actions.getSelected(this.props.vehicleJourneys).length != 1 || this.props.disabled)}
            data-toggle='modal'
            data-target='#NotesEditVehicleJourneyModal'
            title={ I18n.t('vehicle_journeys.form.hint_line_notice') }
            onClick={() => this.props.onOpenNotesEditModal(actions.getSelected(this.props.vehicleJourneys)[0])}
          >
            <span className='fa fa-sticky-note'></span>
          </button>

          <div className={ 'modal fade ' + ((this.props.modal.type == 'duplicate') ? 'in' : '') } id='NotesEditVehicleJourneyModal'>
            <div className='modal-container'>
              <div className='modal-dialog'>
                <div className='modal-content'>
                  <div className='modal-header'>
                    <h4 className='modal-title'>{I18n.t('vehicle_journeys.form.footnotes')}</h4>
                    <span type="button" className="close modal-close" data-dismiss="modal">&times;</span>
                  </div>

                  {(this.props.modal.type == 'notes_edit') && (
                    <form>
                      <div className='modal-body'>
                        {this.renderAssociatedFN()}
                        {this.props.editMode && this.renderToAssociateFN()}
                      </div>
                      {
                        this.props.editMode &&
                        <div className='modal-footer'>
                          <button
                            className='btn btn-cancel'
                            data-dismiss='modal'
                            type='button'
                            onClick={this.props.onModalClose}
                          >
                            {I18n.t('cancel')}
                        </button>
                          <button
                            className='btn btn-default'
                            type='button'
                            onClick={this.handleSubmit.bind(this)}
                          >
                            {I18n.t('actions.submit')}
                        </button>
                        </div>
                      }
                    </form>
                  )}

                </div>
              </div>
            </div>
          </div>
        </li>
      )
    } else {
      return false
    }
  }
}

NotesEditVehicleJourney.propTypes = {
  onOpenNotesEditModal: PropTypes.func.isRequired,
  onModalClose: PropTypes.func.isRequired,
  onToggleFootnoteModal: PropTypes.func.isRequired,
  onNotesEditVehicleJourney: PropTypes.func.isRequired,
  disabled: PropTypes.bool.isRequired
}
