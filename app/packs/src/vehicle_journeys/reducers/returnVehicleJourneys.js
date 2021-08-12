import _ from 'lodash'
import actions from '../actions'

export default function returnVehicleJourneys(state = [], action) {
  switch (action.type) {
    case 'RECEIVE_RETURN_VEHICLE_JOURNEYS':
      return [...action.json]
        default:
      return state
  }
}
