import PropTypes from 'prop-types'
import SaveButton from '../../../src/helpers/save_button'
export default class SaveShape extends SaveButton {
  constructor(props) {
    super(props)

    this.state = {
      hasPolicy: false
    }

    this.handleClick = this.handleClick.bind(this)
  }

  get policy() {
    return this.props.isEdit ? 'canUpdate' : 'canCreate'
  }

  componentDidUpdate(prevProps, prevState) {
    const { permissions: prevPermissions } = prevProps
    const { permissions } = this.props

    if (prevPermissions[this.policy] != permissions[this.policy]) {
      this.setState({ hasPolicy: permissions[this.policy] })
    }
  }

  btnDisabled() {
    return !this.state.hasPolicy
  }

  hasPolicy() {
    return this.state.hasPolicy
  }

  formClassName() {
    return 'shape'
  }

  handleClick(e) {
    this.props.onSubmit(e)
  }
}

SaveShape.propTypes = {
  permissions: PropTypes.object.isRequired,
  isEdit: PropTypes.bool.isRequired,
  onSubmit: PropTypes.func.isRequired
}

SaveShape.defaultProps = {
  editMode: true,
  permissions: []
}
