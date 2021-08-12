import { combineReducers } from 'redux'
import formErrors from './formErrors'
import oppositeRoutes from './oppositeRoutes'
import route from './route'
import status from './status'
import stopPoints from './stopPoints'
import deletedStopPoints from './deletedStopPoints'

const routesApp = combineReducers({
  route,
  oppositeRoutes,
  stopPoints,
  deletedStopPoints,
  status,
  formErrors
})

export default routesApp
