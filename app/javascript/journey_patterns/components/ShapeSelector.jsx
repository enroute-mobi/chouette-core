import _ from 'lodash'
import React, { Component } from 'react'
import PropTypes from 'prop-types'
import Select2 from 'react-select2-wrapper'
import language from '../../helpers/select2/language.js'

export default class BSelect4 extends Component {
  constructor(props) {
    super(props)
  }

  displayData() {
    return this.props.shape ? (this.props.shape.name || this.props.shape.uuid) : undefined
  }

  render() {
    let placeHolder = I18n.t('')
    return (
      <Select2
        data={[this.displayData()]}
        value={this.displayData()}
        onSelect={(e) => this.props.onSelectShape(e) }
        onUnselect={() => this.props.onUnselectShape()}
        disabled={this.props.disabled}
        multiple={false}
        ref='shape_id'
        options={{
          language,
          allowClear: true,
          theme: 'bootstrap',
          width: '100%',
          placeholder: I18n.t('journey_patterns.form.shape_placeholder'),
          ajax: {
            url: window.shapes_url + ".json",
            dataType: 'json',
            delay: '500',
            data: (params) => ({ q: { name_or_uuid_cont: params.term} }),
            processResults: (data, params) => ({
              results: data.map(
                item => _.assign(
                  {},
                  item,
                  {
                    text: _.truncate((item.name ? item.name+" | "+item.uuid : item.uuid), {'length': 30})
                  }
                )
              )
            }),
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
  if(props.text) { return props.text }
}
