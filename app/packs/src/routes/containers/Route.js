import  { connect } from 'react-redux'
import RouteForm from '../components/form'
import actions from '../actions'

import {
  handleInputChange,
  getWayback,
  directionHandler,
  FETCH_ROUTE_SUCCESS,
  FETCH_ROUTE_ERROR,
} from '../reducers/route'

const mapStateToProps = ({ route, oppositeRoutes, formErrors, status }) => ({
  route,
  isOutbound: route.wayback === 'outbound',
  errors: formErrors.route,
  oppositeRoutesOptions: oppositeRoutes[route.wayback] || []
})

const mapDispatchToProps = (dispatch) => ({
  onUpdateName(e) {
    const newName = handleInputChange('name')(e.target.value)()
    dispatch(actions.updateRouteFormInput(newName))
  },
  onUpdatePublishedName(e) {
    const newPublishedName = handleInputChange('published_name')(e.target.value)()
    dispatch(actions.updateRouteFormInput(newPublishedName))
  },
  onUpdateWayback(e) {
    const newAtributes  = handleInputChange('wayback')(getWayback(e))()
    dispatch(actions.updateRouteFormInput(newAtributes))
  },
  onUpdateOppositeRoute(e) {
    const newOppositeRouteId = handleInputChange('opposite_route_id')(parseInt(e.target.value) || undefined)()
    dispatch(actions.updateRouteFormInput(newOppositeRouteId))
  }
})

const Route = connect(mapStateToProps,mapDispatchToProps)(RouteForm)

export default Route
