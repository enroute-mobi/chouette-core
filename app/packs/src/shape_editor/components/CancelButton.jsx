import CancelButton from '../../../src/helpers/cancel_button'
export default class CancelShape extends CancelButton {
  constructor(props) {
    super(props)
  }

  btnDisabled() {
    return false
  }

  formClassName() {
    return 'shape'
  }
}
