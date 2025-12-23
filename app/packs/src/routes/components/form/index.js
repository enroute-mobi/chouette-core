import React, { Component } from 'react'
import PropTypes from 'prop-types'
import TextInput from './TextInput'
import SelectInput from './SelectInput'
import SwitchInput from './SwitchInput'

export default class RouteForm extends Component {
  constructor(props) {
    super(props)
  }

  render() {
    const {
      route,
      isOutbound,
      errors,
      submitError = false,
      serverErrors = [],
      onUpdateName,
      onUpdatePublishedName,
      onUpdateWayback,
      onUpdateOppositeRoute,
      oppositeRoutesOptions
    } = this.props
    return (
      <div>
        <div>
          {submitError && Array.isArray(serverErrors) && serverErrors.length > 0 && (
            <div className='row'>
              <div className='col-lg-12'>
                <div className="alert alert-danger mt-sm mb-sm">
                  <strong> {I18n.t('error')} : </strong>
                  {serverErrors.map((error, i) => (
                    <ul key={i}>
                      <li>{error}</li>
                      <br />
                    </ul>
                  ))}
                </div>
              </div>
            </div>
          )}
        </div>
        <form className='form-horizontal' id='route_form'>
          <div className='row'>
            <div className='col-lg-12'>
              <TextInput
                inputId='route_name'
                inputName='route[name]'
                labelText={I18n.t('activerecord.attributes.route.name')}
                required
                value={route.name}
                onChange={onUpdateName}
                hasError={errors.name}
              />
              <TextInput
                inputId='route_published_name'
                inputName='route[published_name]'
                labelText={I18n.t('activerecord.attributes.route.published_name')}
                value={route.published_name}
                onChange={onUpdatePublishedName}
                hasError={errors.published_name}
              />
              <SwitchInput
                inputId='route_wayback'
                name='route[wayback]'
                labelText={I18n.t('activerecord.attributes.route.wayback')}
                onChange={onUpdateWayback}
                isChecked={route.wayback === 'outbound'}
              />
              <SelectInput
                inputId='route_opposite_route_id'
                inputName='route[opposite_route_id]'
                labelText={I18n.t('activerecord.attributes.route.opposite_route')}
                value={route.opposite_route_id}
                onChange={onUpdateOppositeRoute}
                options={oppositeRoutesOptions}
              />
            </div>
          </div>
        </form>
      </div>
    )
  }
}

RouteForm.propTypes = {
  route: PropTypes.object,
  isOutbound: PropTypes.bool.isRequired,
  errors: PropTypes.object.isRequired,
  submitError: PropTypes.bool.isRequired,
  serverErrors: PropTypes.array.isRequired,
  oppositeRoutesOptions: PropTypes.array.isRequired
}
