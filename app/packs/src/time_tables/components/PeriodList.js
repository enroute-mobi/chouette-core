import React, { Component } from 'react'
import PropTypes from 'prop-types'

export default class PeriodList extends Component {
  constructor(props) {
    super(props)
    this.state = {
      display: false
    }
    this.toggleDisplay = this.toggleDisplay.bind(this)
  }

  toggleDisplay() {
    this.setState({
      display: !this.state.display
    })
  }

  render() {
    return (
      <div className="container-fluid">
        <div className="row">
          <div className="col xs-9 col-xs-offset-3">
            <div className="definition-list">
              <div className="dl-head" style={{display: "flex"}}>
                <div className='btn'
                  data-toggle='modal'
                  data-target='#NewVehicleJourneyModal'
                  title={ I18n.t('time_tables.edit.period_form.display') }
                  onClick={() => this.toggleDisplay()}
                >
                  <span style={{ "verticalAlign": "middle"}} className={"fa " + (this.state.display ? 'fa-minus':'fa-plus')}></span>
                </div>
                <div>
                  <span style={{ "verticalAlign": "middle"}}>{ I18n.t('time_tables.edit.period_form.all_periods') }</span>
                </div>
              </div>
              <div className={"dl-checkboxes foldable-content " + (this.state.display ? 'fade':'')}>
                {this.props.timetable.time_table_periods.map((p, i) => {
                  return !p.deleted && (
                    <div key={i} className="dl-checkboxes-groups">
                      <div className="dl-cb-group-content">
                        <div className="row vertical-align">
                          <div className="col-xs-4" style={{fontWeight: "bold"}}>
                            {(new Date(p.period_start)).toLocaleDateString(I18n.locale)}
                          </div>
                          <div className="col-xs-4" style={{fontWeight: "bold"}}>
                            {(new Date(p.period_end)).toLocaleDateString(I18n.locale)}
                          </div>
                          <div className="col-xs-4 btn-group">
                            <div className="btn btn-link"
                              title={ I18n.t('time_tables.edit.period_form.display_period') }
                              onClick={(e) => this.props.onZoomOnPeriod(e, p, this.props.pagination, this.props.metas, this.props.timetable )}
                            >
                              <span className='fa fa-search'></span>
                            </div>
                            <div className="btn btn-link"
                              title={ I18n.t('actions.edit') }
                              onClick={() => this.props.onOpenEditPeriodForm(p, i)}
                            >
                              <span className='fa fa-pencil-alt'></span>
                            </div>
                            <div className="btn btn-link"
                              title={ I18n.t('actions.delete') }
                              onClick={() => this.props.onDeletePeriod(i, this.props.metas.day_types)}
                            >
                              <span className='fa fa-trash text-danger'></span>
                            </div>
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
