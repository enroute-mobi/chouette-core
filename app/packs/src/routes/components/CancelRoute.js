import CancelButton from '../../helpers/cancel_button'

export default class CancelRoute extends CancelButton {
  constructor(props) {
    super(props)
  }

  formClassName() {
    return 'route'
  }
}