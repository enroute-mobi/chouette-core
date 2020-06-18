import React, { Component } from 'react'
import PropTypes from 'prop-types'

export default class PeriodList extends Component {
  constructor(props) {
    super(props)
    this.state = {
      display: false
    }
    this.tooggleDisplay = this.tooggleDisplay.bind(this);
  }

  tooggleDisplay() {
    this.setState({
      display: !this.state.display
    })
  }

  render() {
    return (
      <div className="container-fluid">
        <div className="row">
          <div className="col lg-6 col-lg-offset-3">
            <div className="definition-list">
              <div className="dl-head" style={{display: "flex"}}>
                <button
                  type='button'
                  data-toggle='modal'
                  data-target='#NewVehicleJourneyModal'
                  className='dark-action-button'
                  title={ I18n.t('time_tables.edit.period_form.display') }
                  onClick={() => this.tooggleDisplay()}
                >
                  <span className={"fa " + (this.state.display ? 'fa-minus':'fa-plus')}></span>
                </button>
                <div style={{alignSelf: "flex-end"}}>
                  { I18n.t('time_tables.edit.period_form.all_periods') }
                </div>
              </div>
              <div className={"dl-checkboxes foldable-content " + (this.state.display ? '':'fade')}>
                {this.props.timetable.time_table_periods.map((p, i) => {
                  return !p.deleted && (
                    <div key={i} className="dl-checkboxes-groups">
                      <div className="dl-cb-group-content">
                        <div className="row vertical-align">
                          <div className="col-xs-2 col-xs-offset-2" style={{fontWeight: "bold"}}>
                            {p.period_start.replace(/-/g, '/')}
                          </div>
                          <div className="col-xs-2 col-xs-offset-2" style={{fontWeight: "bold"}}>
                            {p.period_end.replace(/-/g, '/')}
                          </div>
                          <div className="col-xs-2">
                            <button
                              type='button'
                              className='dark-action-button'
                              title={ I18n.t('time_tables.edit.period_form.display_period') }
                              onClick={(e) => this.props.onZoomOnPeriod(e, p, this.props.pagination, this.props.metas, this.props.timetable )}
                            >
                              <span className='fa fa-search'></span>
                            </button>
                            <button
                              type='button'
                              className='dark-action-button'
                              title={ I18n.t('actions.edit') }
                              onClick={() => this.props.onOpenEditPeriodForm(p, i)}
                            >
                              <span className='fa fa-pencil'></span>
                            </button>
                            <button
                              type='button'
                              className='dark-action-button'
                              title={ I18n.t('actions.delete') }
                              onClick={() => this.props.onDeletePeriod(i, this.props.metas.day_types)}
                            >
                              <span className='fa fa-trash'></span>
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>
          </div>
        </div>
      </div>
    )
  }
}

PeriodList.propTypes = {
  metas: PropTypes.object.isRequired,
  timetable: PropTypes.object.isRequired,
  status: PropTypes.object.isRequired,
  onDeletePeriod: PropTypes.func.isRequired,
  onOpenEditPeriodForm: PropTypes.func.isRequired
}
