import React from 'react'
import { connect } from 'react-redux'
import actions from '../actions/'

let AddStopPoint = ({ dispatch }) => {
  return (
    <div className="nested-linker">
      <form onSubmit={e => {
        e.preventDefault()
        dispatch(actions.closeMaps())
        dispatch(actions.addStop())
      }}>
        <button type="submit" className="btn btn-primary">
          {I18n.t('stop_areas.actions.new')}
        </button>
      </form>
    </div>
  )
}
export default AddStopPoint = connect()(AddStopPoint)
