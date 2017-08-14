var React = require('react')
var Component = require('react').Component
var PropTypes = require('react').PropTypes
var actions = require('../actions')
var _ = require('lodash')

class SaveTimetable extends Component{
  constructor(props){
    super(props)
  }

  render() {
    const error = actions.errorModalKey(this.props.timetable.time_table_periods, this.props.metas.day_types)

    return (
      <div className='row mt-md'>
        <div className='col-lg-12 text-right'>
          <form className='time_tables formSubmitr ml-xs' onSubmit={e => {e.preventDefault()}}>
            <button
              className='btn btn-default'
              type='button'
              onClick={e => {
                e.preventDefault()
                if (error) {
                  this.props.onShowErrorModal(error)
                } else {
                  actions.submitTimetable(this.props.getDispatch(), this.props.timetable, this.props.metas)
                }
              }}
            >
              Valider
            </button>
          </form>
        </div>
      </div>
    )
  }
}

SaveTimetable.propTypes = {
  timetable: PropTypes.object.isRequired,
  status: PropTypes.object.isRequired,
  metas: PropTypes.object.isRequired
}

module.exports = SaveTimetable
