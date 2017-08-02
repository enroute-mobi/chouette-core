var React = require('react')
var Component = require('react').Component
var PropTypes = require('react').PropTypes
var actions = require('../actions')

class JourneyPattern extends Component{
  constructor(props){
    super(props)
    this.previousCity = undefined
  }

  vehicleJourneyURL(jpOid) {
    let routeURL = window.location.pathname.split('/', 7).join('/')
    let vjURL = routeURL + '/vehicle_journeys?jp=' + jpOid

    return (
      <a href={vjURL}>Horaires des courses</a>
    )
  }

  cityNameChecker(sp) {
    let bool = false
    if(sp.city_name != this.previousCity){
      bool = true
      this.previousCity = sp.city_name
    }
    return (
      <div
        className={(bool) ? 'headlined' : ''}
      >
        <span className='has_radio'>
          <input
            onChange = {(e) => this.props.onCheckboxChange(e)}
            type='checkbox'
            id={sp.id}
            checked={sp.checked}
            disabled={(this.props.value.deletable || this.props.status.policy['journey_patterns.update'] == false || this.props.status.editMode == false) ? 'disabled' : ''}
            >
          </input>
          <span className='radio-label'></span>
        </span>
      </div>
    )
  }

  getErrors(errors) {
    let err = Object.keys(errors).map((key, index) => {
      return (
        <li key={index} style={{listStyleType: 'disc'}}>
          <strong>{key}</strong> { errors[key] }
        </li>
      )
    })

    return (
      <ul className="alert alert-danger">{err}</ul>
    )
  }

  render() {
    this.previousCity = undefined

    return (
      <div className={'t2e-item' + (this.props.value.deletable ? ' disabled' : '') + (this.props.value.object_id ? '' : ' to_record') + (this.props.value.errors ? ' has-error': '')}>
        {/* Errors */}
        {/* this.props.value.errors ? this.getErrors(this.props.value.errors) : '' */}

        <div className='th'>
          <div className='strong mb-xs'>{this.props.value.object_id ? actions.humanOID(this.props.value.object_id) : '-'}</div>
          <div>{this.props.value.registration_number}</div>
          <div>{actions.getChecked(this.props.value.stop_points).length} arrêt(s)</div>

          <div className={this.props.value.deletable ? 'btn-group disabled' : 'btn-group'}>
            <div
              className={this.props.value.deletable ? 'btn dropdown-toggle disabled' : 'btn dropdown-toggle'}
              data-toggle='dropdown'
              >
              <span className='fa fa-cog'></span>
            </div>
            <ul className='dropdown-menu'>
              <li className={(this.props.status.policy['journey_patterns.update'] == false || this.props.status.editMode == false) ? 'disabled' : ''}>
                <button
                  type='button'
                  onClick={this.props.onOpenEditModal}
                  data-toggle='modal'
                  data-target='#JourneyPatternModal'
                  >
                  Editer
                </button>
              </li>
              <li className={this.props.value.object_id ? '' : 'disabled'}>
                {this.vehicleJourneyURL(this.props.value.object_id)}
              </li>
              <li className={'delete-action' + ((this.props.status.policy['journey_patterns.destroy'] == false || this.props.status.editMode == false) ? ' disabled' : '')}>
                <button
                  type='button'
                  disabled={(this.props.status.policy['journey_patterns.destroy'] == false || this.props.status.editMode == false)? 'disabled' : ''}
                  onClick={(e) => {
                    e.preventDefault()
                    this.props.onDeleteJourneyPattern(this.props.index)}
                  }
                  >
                    <span className='fa fa-trash'></span>Supprimer
                  </button>
                </li>
              </ul>
            </div>
          </div>

          {this.props.value.stop_points.map((stopPoint, i) =>{
            return (
              <div key={i} className='td'>
                {this.cityNameChecker(stopPoint)}
              </div>
            )
          })}
        </div>
      )
  }
}

JourneyPattern.propTypes = {
  value: PropTypes.object,
  index: PropTypes.number,
  onCheckboxChange: PropTypes.func.isRequired,
  onOpenEditModal: PropTypes.func.isRequired,
  onDeleteJourneyPattern: PropTypes.func.isRequired
}

module.exports = JourneyPattern
