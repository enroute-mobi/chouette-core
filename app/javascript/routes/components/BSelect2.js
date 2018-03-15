import _ from'lodash'
import React, { Component } from 'react'
import PropTypes from 'prop-types'
import Select2 from 'react-select2-wrapper'


// get JSON full path
var origin = window.location.origin
var path = window.location.pathname.split('/', 3).join('/')


export default class BSelect3 extends Component {
  constructor(props, context) {
    super(props, context)
  }
  onChange(e) {
    this.props.onChange(this.props.index, {
      text: e.currentTarget.textContent,
      stoparea_id: e.currentTarget.value,
      stoparea_kind: e.params.data.kind,
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
    if(this.props.value.edit)
      return (
        <div className='select2-bootstrap-append'>
          <BSelect2 {...this.props} onSelect={ this.onChange.bind(this) }/>
        </div>
      )
    else
      if(!this.props.value.stoparea_id)
        return (
          <div>
            <BSelect2 {...this.props} onSelect={ this.onChange.bind(this) }/>
          </div>
        )
      else
        return (
          <a
            className='navlink'
            href={origin + path + '/stop_areas/' + this.props.value.stoparea_id}
            title="Voir l'arrêt"
          >
            {this.parsedText(this.props.value.text)}
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
        value={ this.props.value.stoparea_id }
        onSelect={ this.props.onSelect }
        ref='newSelect'
        options={{
          placeholder: this.context.I18n.t("routes.edit.select2.placeholder"),
          allowClear: true,
          language: 'fr', /* Doesn't seem to work... :( */
          theme: 'bootstrap',
          width: '100%',
          ajax: {
            url: origin + path + '/autocomplete_stop_areas.json',
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
                      var text = item.name;
                      if (item.zip_code || item.short_city_name) {
                          text += ","
                      }
                      if (item.zip_code) {
                          text += ` ${item.zip_code}`
                      }
                      if (item.short_city_name) {
                          text += ` ${item.short_city_name}`
                      }
                      text += ` <small><em>(${item.area_type.toUpperCase()}, ${item.user_objectid})</em></small>`;
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

BSelect2.contextTypes = {
  I18n: PropTypes.object
}
