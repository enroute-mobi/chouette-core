import React from 'react'
import { connect } from 'react-redux'
import actions from '../actions'
import NavigateComponent from '../components/Navigate'

const mapStateToProps = (state) => {
  return {
    metas: state.metas,
    timetable: state.timetable,
    status: state.status,
    pagination: state.pagination
  }
}


const Navigate = connect(mapStateToProps)(NavigateComponent)

export default Navigate
