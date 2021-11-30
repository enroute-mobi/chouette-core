import React, { Component } from 'react'
import PropTypes from 'prop-types'
import _ from 'lodash'
import JourneyPattern from './JourneyPattern'
import StopAreaHeaderManager from '../../helpers/stop_area_header_manager'

export default class JourneyPatterns extends Component {
  constructor(props){
    super(props)
    this.headerManager = new StopAreaHeaderManager(
      _.map(this.props.stopPointsList, (sp, i)=>{return sp.stop_area_object_id + "-" + i}),
      this.props.stopPointsList,
      this.props.status.features
    )
  }

  componentDidMount() {
    this.props.onLoadFirstPage()
  }

  componentDidUpdate(prevProps, prevState) {
    if(this.props.status.isFetching == false){
      $('.table-2entries').each(function() {
        var refH = []
        var refCol = []

        $(this).find('.t2e-head').children('div').each(function() {
          var h = this.getBoundingClientRect().height;
          refH.push(h)
        });

        var i = 0
        $(this).find('.t2e-item').children('div').each(function() {
          var h = this.getBoundingClientRect().height;
          if(refCol.length < refH.length){
            refCol.push(h)
          } else {
            if(h > refCol[i]) {
              refCol[i] = h
            }
          }
          if(i == (refH.length - 1)){
            i = 0
          } else {
            i++
          }
        });

        for(var n = 0; n < refH.length; n++) {
          if(refCol[n] < refH[n]) {
            refCol[n] = refH[n]
          }
        }

        $(this).find('.th').css('height', refCol[0]);

        for(var nth = 1; nth < refH.length; nth++) {
          $(this).find('.td:nth-child('+ (nth + 1) +')').css('height', refCol[nth]);
        }
      });
    }
  }

  showHeader(object_id) {
    return this.headerManager.showHeader(object_id)
  }

  hasFeature(key) {
    return this.props.status.features[key]
  }

  render() {
    this.previousCity = undefined
    requestAnimationFrame(function(){
      $(document).trigger("table:updated")
    })
    if(this.props.status.isFetching == true) {
      return (
        <div className="isLoading" style={{marginTop: 80, marginBottom: 80}}>
          <div className="loader"></div>
        </div>
      )
    } else {
      return (
        <div className='row'>
          <div className='col-lg-12'>
            {(this.props.status.fetchSuccess == false) && (
              <div className="alert alert-danger mt-sm">
                <strong>{I18n.t('error')} : </strong>
                {I18n.t('journeys_patterns.journey_pattern.fetching_error')}
              </div>
            )}

            { _.some(this.props.journeyPatterns, 'errors') && (
              <div className="alert alert-danger mt-sm">
                <strong> {I18n.t('error')} : </strong>
                {this.props.journeyPatterns.map((jp, index) =>
                  jp.errors && Object.keys(jp.errors).map((key) =>
                    jp.errors[key].map((error, i) => {
                      return (
                        <ul key={i}>
                          <li>{jp.errors[key]}</li>
                          <br />
                        </ul>
                      )
                    })
                  )
                )}
              </div>
            )}

            <div className={'table table-2entries mt-sm mb-sm' + ((this.props.journeyPatterns.length > 0) ? '' : ' no_result')}>
              <div className='t2e-head w20'>
                <div className='th'>
                  <div className='strong mb-xs'>{I18n.t('objectid')}</div>
                  <div>{I18n.attribute_name('journey_pattern', 'registration_number')}</div>
                  <div>{I18n.attribute_name('journey_pattern', 'stop_points')}</div>
                  { this.hasFeature('costs_in_journey_patterns') &&
                     <div>
                       <div>{I18n.attribute_name('journey_pattern', 'full_journey_time')}</div>
                       <div>{I18n.attribute_name('journey_pattern', 'commercial_journey_time')}</div>
                     </div> }
                </div>
                {this.props.stopPointsList.map((sp, i) =>{
                  return (
                    <div key={i} className={'td' + (this.hasFeature('costs_in_journey_patterns') ? ' with-costs' : '')}>
                      {this.headerManager.stopPointHeader(sp.stop_area_object_id + "-" + i)}
                    </div>
                  )
                })}
              </div>

              <div className='t2e-item-list w80'>
                <div>
                  {this.props.journeyPatterns.map((journeyPattern, index) =>
                    <JourneyPattern
                      enterEditMode={this.props.enterEditMode}
                      fetchingApi={this.props.fetchingApi}
                      fetchJourneyPatterns={this.props.fetchJourneyPatterns}
                      onDuplicateJourneyPattern={this.props.onDuplicateJourneyPattern}
                      value={ journeyPattern }
                      key={ index }
                      onCheckboxChange= {(e) => this.props.onCheckboxChange(e, index)}
                      onOpenEditModal= {() => this.props.onOpenEditModal(index, journeyPattern)}
                      onDeleteJourneyPattern={() => this.props.onDeleteJourneyPattern(index)}
                      onUpdateJourneyPatternCosts={(costs) => this.props.onUpdateJourneyPatternCosts(index, costs)}
                      status= {this.props.status}
                      editMode= {this.props.editMode}
                      showHeader={this.showHeader.bind(this)}
                      fetchRouteCosts={(costsKey) => this.props.fetchRouteCosts(costsKey, index)}
                      />
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      )
    }
  }
}

JourneyPatterns.propTypes = {
  journeyPatterns: PropTypes.array.isRequired,
  stopPointsList: PropTypes.array.isRequired,
  status: PropTypes.object.isRequired,
  onCheckboxChange: PropTypes.func.isRequired,
  onLoadFirstPage: PropTypes.func.isRequired,
  fetchingApi: PropTypes.func.isRequired,
  fetchJourneyPatterns: PropTypes.func.isRequired,
  onOpenEditModal: PropTypes.func.isRequired,
  fetchRouteCosts: PropTypes.func.isRequired,
  enterEditMode: PropTypes.func.isRequired
}
