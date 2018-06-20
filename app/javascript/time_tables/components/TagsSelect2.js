import React, { Component } from 'react'
import PropTypes from 'prop-types'
import Select2 from 'react-select/lib/Creatable'
import select2Fecth from '../../helpers/select2_fetch_generator.js'

// get JSON full path
const origin = window.location.origin
const path = window.location.pathname.split('/', 4).join('/')

export default class TagsSelect2 extends Component {
  constructor(props) {
    super(props)
    this.handleChange = this.handleChange.bind(this)
    this.handleInputChange = this.handleInputChange.bind(this)
    this.url = origin + path + '/tags.json',

      this.state = {
        inputValue: '',
        options: []
      }
  }

  handleInputChange(inputValue) {
    this.setState({ inputValue })
  }

  handleChange(newValue) {
    let newTags = newValue.reduce((tags, { value, label }) => {
      return [...tags, { value, label }]
    }, [])
    this.props.onSetNewTags(newTags)
  }

  filterResults(collection, input) {
    return collection.filter(i => i.label.toLowerCase().includes(input.toLowerCase()))
  }

  componentDidMount() {
    select2Fecth(this.url, this.state.inputValue, this.filterResults).then(options => this.setState({ options }))
  }

  render() {
    let { filterResults, handleChange, handleInputChange, url, props: { tags }, state: { inputValue, options } } = this
    return (
      <Select2
        name='tags_id'
        isMulti
        isClearable
        inputValue={inputValue}
        value={tags}
        onChange={handleChange}
        onInputChange={handleInputChange}
        placeholder={I18n.t('time_tables.edit.select2.tag.placeholder')}
        options={options}
      />
    )
  }
}

TagsSelect2.propTypes = {
  tags: PropTypes.array.isRequired,
  onSetNewTags: PropTypes.func.isRequired
}