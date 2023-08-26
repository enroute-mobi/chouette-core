import { connect } from 'react-redux'
import actions from '../actions'
import MetasComponent from '../components/Metas'

const mapStateToProps = (state, ownProps) => {
  return {
    metas: state.metas,
    ...ownProps
  }
}

const mapDispatchToProps = dispatch => ({
  onUpdateDayTypes: (index, dayTypes) => {
    let newDayTypes = dayTypes.slice(0)
    newDayTypes[index] = !newDayTypes[index]
    dispatch(actions.updateDayTypes(newDayTypes))
    dispatch(actions.updateCurrentMonthFromDaytypes(newDayTypes))
  },
  onUpdateComment: (comment) => {
    dispatch(actions.updateComment(comment))
  },
  onUpdateColor: (color) => {
    dispatch(actions.updateColor(color))
  },
  onUpdateShared: newValue => {
    dispatch(actions.updateShared(newValue))
  }
})

const Metas = connect(mapStateToProps, mapDispatchToProps)(MetasComponent)

export default Metas
