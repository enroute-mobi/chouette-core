import CancelButton from '../../helpers/cancel_button'

export default class CancelTimetable extends CancelButton {
  constructor(props) {
    super(props)
  }

  formClassName() {
    return 'timetable'
  }
}