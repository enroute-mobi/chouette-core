import _ from 'lodash'
import React, { Component } from 'react'
import PropTypes from 'prop-types'
import Select2 from 'react-select2-wrapper'
import actions from '../../../actions'
import language from '../../../../../src/helpers/select2/language'

// get JSON full path
var origin = window.location.origin
var path = window.location.pathname.split('/', 3).join('/')

export default class BSelect4 extends Component {
  constructor(props) {
    super(props)
  }

  render() {
    return (
      <Select2
        data={(this.props.isFilter) ? [this.props.filters.query.timetable.comment] : undefined}
        value={(this.props.isFilter) ? this.props.filters.query.timetable.comment : undefined}
        onSelect={(e) => this.props.onSelect2Timetable(e) }
        multiple={false}
        ref='timetable_id'
        options={{
          language,
          allowClear: false,
          theme: 'bootstrap',
          width: '100%',
          placeholder: this.props.placeholder,
          ajax: {
            url: origin + path + this.props.chunkURL,
            dataType: 'json',
            delay: '500',
            data: (params) => {
              let q = {}
              q[this.props.searchKey] = params.term
              return {q}
            },
            processResults: function(data, params) {
              return {
                results: data.map(
                  item => {
                    let isPurchaseWindow = item.objectid.includes('PurchaseWindow')
                    let color = item.color ? (isPurchaseWindow ? `#${item.color}` : item.color) : '#4B4B4B'
                    return _.assign(
                      {},
                      item,
                      { text: '<strong>' + "<span class='fa fa-circle' style='color:" + color + "'></span> " + (item.comment || item.name) + ' - ' + item.short_id + '</strong><br/><small>' + (item.day_types ? item.day_types.match(/[A-Z]?[a-z]+/g).join(', ') : "") + '</small>' }
                    )
                  }
                )
              };
            },
            cache: true
          },
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
