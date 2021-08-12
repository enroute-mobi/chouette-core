import _ from 'lodash'
import React, { Component } from 'react'
import PropTypes from 'prop-types'
import Select2 from 'react-select2-wrapper'
import actions from '../../../actions'
import language from '../../../../../src/helpers/select2/language'

// get JSON full path
let origin = window.location.origin
let path = window.location.pathname.split('/', 7).join('/')

export default class BSelect4b extends Component {
  constructor(props) {
    super(props)
  }

  render() {
    return (
      <Select2
        data={(this.props.isFilter) ? [this.props.filters.query.vehicleJourney.objectid] : undefined}
        value={(this.props.isFilter) ? this.props.filters.query.vehicleJourney.objectid : undefined}
        onSelect={(e) => this.props.onSelect2VehicleJourney(e)}
        multiple={false}
        ref='vehicle_journey_objectid'
        options={{
          language,
          allowClear: false,
          theme: 'bootstrap',
          placeholder: I18n.t('vehicle_journeys.vehicle_journeys_matrix.filters.id'),
          width: '100%',
          ajax: {
            url: origin + path + '/vehicle_journeys.json',
            dataType: 'json',
            delay: '500',
            data: function(params) {
              return {
                q: { objectid_cont: params.term},
              };
            },
            processResults: function(data, params) {
              return {
                results: data.vehicle_journeys.map(
                  item => _.assign(
                    {},
                    item,
                    { id: item.objectid, text: item.short_id }
                  )
                )
              };
            },
            cache: true
          },
          minimumInputLength: 1,
          templateResult: formatRepo
        }}
      />
    )
  }
}

const formatRepo = (props) => {
  if(props.text) return props.text
}
