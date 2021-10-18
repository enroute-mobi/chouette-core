import CancelButton from '../../helpers/cancel_button'

export default class CancelVehicleJourney extends CancelButton {
  constructor(props) {
    super(props)
  }

  hasPolicy(){
    return this.props.filters.policy['vehicle_journeys.update'] == true
  }

  formClassName() {
    return 'vj_collection'
  }
}
