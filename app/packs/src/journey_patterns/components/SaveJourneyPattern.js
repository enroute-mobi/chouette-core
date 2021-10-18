import React, { Component } from 'react'
import PropTypes from 'prop-types'
import SaveButton from '../../helpers/save_button'
import actions from '../actions'

export default class SaveJourneyPattern extends SaveButton {
  hasPolicy(){
    return this.props.status.policy['journey_patterns.update'] == true
  }

  formClassName(){
    return 'jp_collection'
  }

  submitForm(){
    this.props.onSubmitJourneyPattern(this.props.dispatch, this.props.journeyPatterns)
  }
}

SaveJourneyPattern.propTypes = {
  journeyPatterns: PropTypes.array.isRequired,
  status: PropTypes.object.isRequired,
  page: PropTypes.number.isRequired
}
