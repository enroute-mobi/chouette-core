import React, { Component } from 'react'
import PropTypes from 'prop-types'
import mapKeys from 'lodash/mapKeys'
import map from 'lodash/map'
import filter from 'lodash/filter'
import assign from 'lodash/assign'
import Select2 from 'react-select2-wrapper'

// get JSON full path
let origin = window.location.origin
let path = window.location.pathname.split('/', 4).join('/')

export default class TagsSelect2 extends Component {
  constructor(props, context) {
    super(props, context)
  }

  mapKeys(array){
    return array.map((item) =>
      mapKeys(item, (v, k) =>
        ((k == 'name') ? 'text' : k)
      )
    )
  }

  handleSelect(e) {
    let tagId = e.params.data['id']
    if (Number.isInteger(tagId)) {
      $(this.refs.tags_id.el).find(`option[value=${tagId}]`).remove()
    } else {
      $(this.refs.tags_id.el).find('[data-select2-tag]').remove()
    }
    this.props.onSelect2Tags(e)
  }

  render() {
    return (
      <Select2
        value={(this.props.tags.length) ? map(this.props.tags, 'id') : undefined}
        data={(this.props.tags.length) ? this.mapKeys(this.props.tags) : undefined}
        onSelect={(e) => this.handleSelect(e)}
        onUnselect={(e) => setTimeout( () => this.props.onUnselect2Tags(e, 150))}
        multiple={true}
        ref='tags_id'
        options={{
          tags:true,
          createTag: function(params) {
            return {name: params.term, text: params.term, id: params.term}
          },
          allowClear: true,
          theme: 'bootstrap',
          width: '100%',
          placeholder: I18n.t('time_tables.edit.select2.tag.placeholder'),
          ajax: {
            url: origin + path + '/tags.json',
            dataType: 'json',
            delay: '500',
            data: function(params) {
              return {
                tag: params.term,
              };
            },
            processResults: function(data, params) {
              let items = filter(data, ({name}) => name.includes(params.term) )
              return {
                results: items.map(
                  item => assign(
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
  if(props.name) return props.name
}
