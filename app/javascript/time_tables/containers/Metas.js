import { connect } from 'react-redux'
import actions from '../actions'
import MetasComponent from '../components/Metas'

const mapStateToProps = (state) => {
  return {
    metas: state.metas
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
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
    onSetNewTags: (newValue) => {
      let newTags = newValue.reduce((tags, { value, label }) => {
          return [...tags, { value, label }]
        }, [])
      dispatch(actions.setNewTags(newTags))
    }
  }
}

const Metas = connect(mapStateToProps, mapDispatchToProps)(MetasComponent)

export default Metas
