import React from 'react'
import { connect } from 'react-redux'
import actions from '../actions/'

let AddStopPoint = ({ dispatch }) => {
  return (
    <div className="nested-linker flex items-center justify-end">
      <form onSubmit={e => {
        e.preventDefault()
        dispatch(actions.closeMaps())
        dispatch(actions.addStop(e.nativeEvent.submitter.className.includes('new_flexible')))
      }}>
        <button type="submit" className="btn btn-primary">
          {I18n.t('stop_areas.actions.new')}
        </button>
        <button type="submit" className="btn btn-primary new_flexible">
          {I18n.t('stop_areas.actions.new_flexible')}
        </button>
      </form>
    </div>
  )
}
export default AddStopPoint = connect()(AddStopPoint)
