import React, { Component } from 'react'
import PropTypes from 'prop-types'
import select2Fecth from './select2_fetch_generator.js'

export default function createSelect2(WrappedComponent) {
  class Select2 extends Component {
    constructor(props) {
      super(props)
      this.handleChange = this.handleChange.bind(this)
      this.handleInputChange = this.handleInputChange.bind(this)
      this.filteredOptions = this.filteredOptions.bind(this)

      this.state = {
        inputValue: '',
        options: []
      }
    }

    handleInputChange(inputValue) {
      this.setState({ inputValue })
    }

    handleChange(newValue) {
      this.props.onHandleChange(newValue)
    }

    filteredOptions() {
      const { options, inputValue } = this.state

      if (inputValue == '') {
        return options
      } else {
        return options.filter(i => i.label.toLowerCase().includes(inputValue.toLowerCase()))
      }
    }

    componentDidMount() {
      select2Fecth(this.props.url).then(options => this.setState({ options }))
    }

    render() {
      const { filteredOptions, handleChange, handleInputChange, props: { value }, state: { inputValue } } = this
      return (
        <WrappedComponent
          inputValue={inputValue}
          value={value}
          options={filteredOptions()}
          onChange={handleChange}
          onInputChange={handleInputChange}
        />)
    }
  }

  Select2.propTypes = {
    url: PropTypes.string.isRequired,
    value: PropTypes.oneOfType([
      PropTypes.array,
      PropTypes.string
    ]).isRequired,
    onHandleChange: PropTypes.func.isRequired
  }

  return Select2
}