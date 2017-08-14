var React = require('react')
var Component = require('react').Component
var PropTypes = require('react').PropTypes
var actions = require('../actions')

class SaveJourneyPattern extends Component{
  constructor(props){
    super(props)
  }

  render() {
    if(this.props.status.policy['journey_patterns.update'] == false) {
      return false
    }else{
      return (
        <div className='row mt-md'>
          <div className='col-lg-12 text-right'>
            <form className='jp_collection formSubmitr ml-xs' onSubmit={e => {e.preventDefault()}}>
              <button
                className='btn btn-default'
                type='button'
                onClick={e => {
                  e.preventDefault()
                  this.props.editMode ? this.props.onSubmitJourneyPattern(this.props.dispatch, this.props.journeyPatterns) : this.props.onEnterEditMode()
                }}
                >
                {this.props.editMode ? "Valider" : "Editer"}
              </button>
            </form>
          </div>
        </div>
      )
    }
  }
}

SaveJourneyPattern.propTypes = {
  journeyPatterns: PropTypes.array.isRequired,
  status: PropTypes.object.isRequired,
  page: PropTypes.number.isRequired
}

module.exports = SaveJourneyPattern
