import CancelButton from '../../helpers/cancel_button'

export default class CancelJourneyPattern extends CancelButton {
  constructor(props) {
    super(props)
  }

  formClassName() {
    return 'jp_collection'
  }
}