import _ from 'lodash'
import React, { Component } from 'react'
import PropTypes from 'prop-types'
import Select2 from 'react-select2-wrapper'
import actions from '../../../actions'
import language from '../../../../../src/helpers/select2/language'

export default class BSelect4 extends Component {
  constructor(props) {
    super(props)
  }

  getSelectedStopAreaId(event) {
    let stop_area_id_string = _.get(event, 'params.data.id')
    return (parseInt(stop_area_id_string) || null)
  }

  render() {
    return (
      <Select2
        data={this.props.data}
        value={this.props.value}
        onSelect={(e) => this.props.onSelectSpecificStop(this.getSelectedStopAreaId(e)) }
        onUnselect={(e) => this.props.onSelectSpecificStop(null)}
        multiple={false}
        disabled={!this.props.editMode}
        ref='stop_area_id'
        options={{
          language,
          allowClear: true,
          theme: 'bootstrap',
          width: '100%',
          placeholder: this.props.placeholder,
          escapeMarkup: function (markup) { return markup },
          templateResult: formatRepo
        }}
      />
    )
  }
}

const formatRepo = (props) => {
  if(props.text) {return props.text}
}
