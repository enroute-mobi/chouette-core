import  { connect } from 'react-redux'
import SaveRouteComponent from '../components/SaveRoute'
import { isActionCreate, getRequestMethod } from '../reducers/status'
import { getStopPointsAttributes } from '../reducers/route'
import actions from '../actions'

const mapStateToProps = (state) => {
  const { name, published_name, wayback, opposite_route_id, line_id } = state.route
  const routeToSubmit = {
    name,
    published_name,
    wayback,
    opposite_route_id,
    line_id,
    stop_points_attributes: getStopPointsAttributes(state)
  }

  return {
    route: state.route,
    stopPoints: state.stopPoints,
    status: state.status,
    editMode: state.status.editMode,
    requestMethod: getRequestMethod(state.status),
    routeToSubmit
  }
}

const mapDispatchToProps = (dispatch) => ({
  onSubmitRoute(route, requestMethod) {
    actions.submitRoute(dispatch)(requestMethod)(route)
  },
  onValidateField(error) {
    dispatch(actions.validateField(error))
  }
})

const SaveRoute = connect(mapStateToProps,mapDispatchToProps)(SaveRouteComponent)

export default SaveRoute