import { connect } from 'react-redux'
import actions from '../actions'
import CodesListComponent from '../components/CodesList'

const mapStateToProps = (state) => {
  return {
    metas: state.metas,
    codes: state.metas.codes
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onAddCode: (index) => {
      dispatch(actions.addCode(index))
    },
    onDeleteCode: (index) => {
      dispatch(actions.deleteCode(index))
    },
    onUpdateCode: (index, newCode) => {
      dispatch(actions.updateCode(index, newCode))
    }
  }
}

const CodesList = connect(mapStateToProps, mapDispatchToProps)(CodesListComponent)

export default CodesList
