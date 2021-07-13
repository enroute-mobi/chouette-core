import { isEqual } from 'lodash'

import SaveButton from '../../../helpers/save_button'
import eventEmitter from '../shape.event-emitter'

export default class SaveShape extends SaveButton {
  constructor(props) {
    super(props)

    this.state = {
      disabled: false
    }
  }

  // shouldComponentUpdate(nextProps, _nextState) {
  //   // console.log('shouldComponentUpdate', this.props.permissions, nextProps.permissions, !isEqual(
  //   //   this.props.permissions,
  //   //   nextProps.permissions
  //   // ))
  //   // return !isEqual(
  //   //   this.props.permissions,
  //   //   nextProps.permissions
  //   // )

  //   return true
  // }

  btnDisabled() {
    return this.state.disabled
  }

  hasPolicy() {
    return true
    const { isEdit, permissions } = this.props
    const policy = isEdit ? 'canUpdate' : 'canCreate'

    return permissions[policy]
  }

  formClassName() {
    return 'shape'
  }

  handleClick(e) {
    eventEmitter.emit('shape:submit')
  }
}
