import { connect } from 'react-redux'
import actions from '../actions'
import CodesListComponent from '../components/CodesList'

const mapStateToProps = (state) => {
  return {
    codeValues: state.timetable.code_values,
    modelClass: state.metas.model_class
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onAddCode: (code) => {
      dispatch(actions.addCode(code))
    },
    onDeleteCode: (index) => {
      dispatch(actions.deleteCode(index))
    },
    onUpdateCode: (attributes) => {
      dispatch(actions.updateCode(attributes))
    }
  }
}

const CodesList = connect(mapStateToProps, mapDispatchToProps)(CodesListComponent)

export default CodesList
