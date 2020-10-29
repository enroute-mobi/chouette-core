import _ from 'lodash'
import React, { Component } from 'react'
import PropTypes from 'prop-types'
import Select2 from 'react-select2-wrapper'
import actions from '../../../actions'
import language from '../../../../helpers/select2/language'

// get JSON full path
let origin = window.location.origin
let path = window.companies_path
let line = window.location.pathname.split('/')[4]

export default class BSelect4 extends Component {
  constructor(props) {
    super(props)
  }

  render() {
    let placeHolder = I18n.t('')
    return (
      <Select2
        data={(this.props.company) ? [this.props.company.name] : undefined}
        value={(this.props.company) ? this.props.company.name : undefined}
        onSelect={(e) => this.props.onSelect2Company(e) }
        onUnselect={() => this.props.onUnselect2Company()}
        disabled={!this.props.editMode && this.props.editModal}
        multiple={false}
        ref='company_id'
        options={{
          language,
          allowClear: true,
          theme: 'bootstrap',
          width: '100%',
          placeholder: I18n.t('vehicle_journeys.vehicle_journeys_matrix.affect_company'),
          ajax: {
            url: path + '.json',
            dataType: 'json',
            delay: '500',
            data: function(params) {
              return {
                q: { name_cont: params.term, line_id_eq: line },
              };
            },
            processResults: function(data, params) {

              return {
                results: data.map(
                  item => _.assign(
                    {},
                    item,
                    {text: item.name}
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
