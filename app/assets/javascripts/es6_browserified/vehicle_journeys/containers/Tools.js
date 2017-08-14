var connect = require('react-redux').connect
var ToolsComponent = require('../components/Tools')
var actions = require('../actions')

const mapStateToProps = (state) => {
  return {
    vehicleJourneys: state.vehicleJourneys,
    editMode: state.editMode,
    filters: state.filters
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onCancelSelection: () => {
      dispatch(actions.cancelSelection())
    }
  }
}

const Tools = connect(mapStateToProps, mapDispatchToProps)(ToolsComponent)

module.exports = Tools
