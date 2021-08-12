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

  render() {
    return (
      <Select2
        data={this.props.data}
        value={this.props.value}
        onSelect={(e) => this.props.onSelectConstraintZone(e) }
        multiple={false}
        ref='constraint_zone_id'
        options={{
          language,
          allowClear: false,
          theme: 'bootstrap',
          width: '100%',
          placeholder: this.props.placeholder,
          minimumInputLength: 1,
          escapeMarkup: function (markup) { return markup; },
          templateResult: formatRepo
        }}
      />
    )
  }
}

const formatRepo = (props) => {
  if(props.text) return props.text
}
