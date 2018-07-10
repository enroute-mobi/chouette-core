import CancelButton from '../../helpers/cancel_button'

export default class CancelVehicleJourney extends CancelButton {
  constructor(props) {
    super(props)
  }

  formClassName() {
    return 'vj_collection'
  }
}