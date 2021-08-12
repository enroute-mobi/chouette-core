import PropTypes from 'prop-types'
import SaveButton from '../../helpers/save_button'
import { handleFormValidation } from '../reducers/formErrors'

export default class SaveRoute extends SaveButton {
  hasPolicy(){
    const { policy, action } = this.props.status
    return policy[`routes.${action}`]
  }

  formClassName(){
    return 'route'
  }

  submitForm(){
    const { route, stopPoints, onValidateField, routeToSubmit, requestMethod, onSubmitRoute } = this.props

    const invalidIndexes = stopPoints.reduce((array, sp, index) => {
        return !!sp.stoparea_id ? array : array.concat(index)
      }, [])

    // Check route length
    onValidateField(handleFormValidation('stopPoints')('invalidLength')(stopPoints.length < 2))

    // Check empty stop Points
    onValidateField(handleFormValidation('stopPoints')('invalidStopPointIndexes')(invalidIndexes))

    // Check route required attributes
    onValidateField(handleFormValidation('route')('name')(!route.name))
    onValidateField(handleFormValidation('route')('published_name')(!route.published_name))

    if (stopPoints.length >= 2 && invalidIndexes.length == 0 && !!route.name && !!route.published_name) {
      onSubmitRoute(routeToSubmit, requestMethod)
    }
  }


}

SaveRoute.propTypes = {
  status: PropTypes.object.isRequired,
  route: PropTypes.object.isRequired,
  stopPoints: PropTypes.array.isRequired,
  editMode: PropTypes.bool.isRequired,
  requestMethod: PropTypes.string.isRequired,
  routeToSubmit: PropTypes.object.isRequired
}