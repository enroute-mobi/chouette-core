var React = require('react')
var Component = require('react').Component
var PropTypes = require('react').PropTypes
var actions = require('../actions')

class ExceptionsInDay extends Component {
  constructor(props) {
    super(props)
  }

  render() {
    {/* display add or remove link, only if true in daytypes */}
      {/* display add or remove link, according to context (presence in period, or not) */}
      if(this.props.value.current_month[this.props.index].in_periods == true && this.props.blueDaytype == true) {
        return (
          <div className='td'>
            <button
              type='button'
              className={'btn btn-circle' + (this.props.value.current_month[this.props.index].excluded_date ? ' active' : '')}
              data-actiontype='remove'
              onClick={(e) => {
                $(e.currentTarget).toggleClass('active')
                this.props.onExcludeDateFromPeriod(this.props.index, this.props.metas.day_types, this.props.currentDate)
              }}
            >
              <span className='fa fa-times'></span>
            </button>
          </div>
        )
      } else if(this.props.value.current_month[this.props.index].in_periods == false) {
        return (
          <div className='td'>
            <button
              type='button'
              className={'btn btn-circle'  + (this.props.value.current_month[this.props.index].include_date ? ' active' : '')}
              data-actiontype='add'
              onClick={(e) => {
                $(e.currentTarget).toggleClass('active')
                this.props.onIncludeDateInPeriod(this.props.index, this.props.metas.day_types, this.props.currentDate)
              }}
            >
              <span className='fa fa-plus'></span>
            </button>
          </div>
        )
      } else if(this.props.value.current_month[this.props.index].in_periods == true && this.props.blueDaytype == false){
        return (
          <div className='td'></div>
        )
      } else{
        return false
      }
  }
}

ExceptionsInDay.propTypes = {
  value: PropTypes.object.isRequired,
  metas: PropTypes.object.isRequired,
  blueDaytype: PropTypes.bool.isRequired,
  onExcludeDateFromPeriod: PropTypes.func.isRequired,
  onIncludeDateInPeriod: PropTypes.func.isRequired,
  index: PropTypes.number.isRequired
}

module.exports = ExceptionsInDay
