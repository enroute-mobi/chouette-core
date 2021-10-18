import actions from '../../actions'
import { connect } from 'react-redux'
import CopyButtonComponent from '../../components/tools/CopyButton'

const mapStateToProps = (_, ownProps) => ({
  disabled: ownProps.disabled
})

const mapDispatchToProps = dispatch => ({
  onClick: () => {
    dispatch(actions.copyClipboard())
  }
})

const CopyButton = connect(mapStateToProps, mapDispatchToProps)(CopyButtonComponent)

export default CopyButton
