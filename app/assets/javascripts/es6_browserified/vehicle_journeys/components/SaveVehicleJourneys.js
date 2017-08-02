var React = require('react')
var Component = require('react').Component
var PropTypes = require('react').PropTypes
var actions = require('../actions')

class SaveVehicleJourneys extends Component{
  constructor(props){
    super(props)
  }

  render() {
    if (this.props.filters.policy['vehicle_journeys.update'] == false) {
      return false
    }else{
      return (
        <div className='row mt-md'>
          <div className='col-lg-12 text-right'>
            <form className='vehicle_journeys formSubmitr ml-xs' onSubmit={e => {e.preventDefault()}}>
              <button
                className='btn btn-default'
                type='button'
                onClick={e => {
                  e.preventDefault()
                  this.props.filters.editMode ? this.props.onSubmitVehicleJourneys(this.props.dispatch, this.props.vehicleJourneys) : this.props.onEnterEditMode(e)
                }}
              >
                {this.props.filters.editMode ? "Valider" : "Editer"}
              </button>
            </form>
          </div>
        </div>
      )
    }
  }
}

SaveVehicleJourneys.propTypes = {
  vehicleJourneys: PropTypes.array.isRequired,
  page: PropTypes.number.isRequired,
  status: PropTypes.object.isRequired,
  filters: PropTypes.object.isRequired,
  onEnterEditMode: PropTypes.func.isRequired,
  onSubmitVehicleJourneys: PropTypes.func.isRequired
}

module.exports = SaveVehicleJourneys
