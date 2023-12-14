import _ from'lodash'
import React, { Component } from 'react'
import PropTypes from 'prop-types'
import Select2 from 'react-select2-wrapper'
import language from '../../helpers/select2/language'


// get JSON full path
var origin = window.location.origin
var path = window.location.pathname.split('/', 3).join('/')


export default class BSelect3 extends Component {
  constructor(props) {
    super(props)
  }
  onChange(e) {
    this.props.onChange(this.props.index, {
      text: e.currentTarget.textContent,
      stoparea_id: parseInt(e.currentTarget.value),
      stoparea_kind: e.params.data.kind,
      stop_area_referential_id: e.params.data.stop_area_referential_id,
      user_objectid: e.params.data.user_objectid,
      longitude: e.params.data.longitude,
      latitude: e.params.data.latitude,
      name: e.params.data.name,
      short_name: e.params.data.short_name,
      city_name: e.params.data.city_name,
      area_type: e.params.data.area_type,
      zip_code: e.params.data.zip_code,
      comment: e.params.data.comment
    })
  }

  parsedText(data) {
    let a = data.replace('</em></small>', '')
    let b = a.split('<small><em>')
    if (b.length > 1) {
      return (
        <span>
          {b[0]}
          <small><em>{b[1]}</em></small>
        </span>
      )
    } else {
      return (
        <span>{data}</span>
      )
    }
  }

  render() {
    const { hasError, value } = this.props
    if(value.edit)
      return (
        <div className={`select2-bootstrap-append ${hasError && 'has-error'}`}>
          <BSelect2 {...this.props} onSelect={ this.onChange.bind(this) }/>
          { hasError && <span className='help-block small'>{I18n.t('activerecord.errors.models.route.attributes.stop_points.empty_stop_point')}</span> }
        </div>
      )
    else
      if(!value.stoparea_id)
        return (
          <div>
            <BSelect2 {...this.props} onSelect={ this.onChange.bind(this) }/>
            { hasError && <span className='help-block small'>{I18n.t('activerecord.errors.models.route.attributes.stop_points.empty_stop_point')}</span> }
          </div>
        )
      else
        return (
          <a
            className='navlink'
            href={origin + '/redirect/stop_areas/' + value.stoparea_id}
            title="Voir l'arrêt"
            dangerouslySetInnerHTML={{__html: value.name }}
          >
          </a>
        )
  }
}

class BSelect2 extends Component{
  componentDidMount() {
    this.refs.newSelect.el.select2('open')
  }

  render() {
    return (
      <Select2
        id={this.props.id}
        value={ this.props.value.stoparea_id }
        onSelect={ this.props.onSelect }
        ref='newSelect'
        options={{
          language,
          placeholder: I18n.t("routes.edit.select2.placeholder"),
          allowClear: true,
          theme: 'bootstrap',
          width: '100%',
          ajax: {
            url: origin + path + '/autocomplete/stop_areas.json',
            dataType: 'json',
            delay: '500',
            data: function(params) {
              return {
                q: params.term,
                scope: 'route_editor'
              };
            },
            processResults: function(data, params) {
              return {
                 results: data.map(
                  function(item) {
                      var text = item.text;
                      // if (item.zip_code || item.short_city_name) {
                      //     text += ","
                      // }
                      // if (item.zip_code) {
                      //     text += ` ${item.zip_code}`
                      // }
                      // if (item.short_city_name) {
                      //     text += ` ${item.short_city_name}`
                      // }
                      // text += ` <small><em>(${item.area_type.toUpperCase()}, ${item.user_objectid})</em></small>`;
                      return _.assign({}, item, { text: text });
                  }
                )
              };
            },
            cache: true
          },
          escapeMarkup: function (markup) { return markup; },
          minimumInputLength: 3
        }}
      />
    )
  }
}
