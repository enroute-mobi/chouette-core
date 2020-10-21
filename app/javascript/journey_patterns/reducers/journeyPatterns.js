import _ from 'lodash'
import actions from "../actions"

const journeyPattern = (state = {}, action) =>{
  switch (action.type) {
    case 'ADD_JOURNEYPATTERN':
      let stopPoints = window.stopPoints

      if(stopPoints != undefined) {
        stopPoints.map((s)=>{
          s.checked = false
          return s
        })
      }
      return {
        name: action.data.name.value,
        published_name: action.data.published_name.value,
        registration_number: action.data.registration_number.value,
        stop_points: stopPoints,
        costs: {},
        custom_fields: action.data.custom_fields,
        deletable: false,
        shape: action.data.shape
      }
    case 'UPDATE_CHECKBOX_VALUE':
      var updatedStopPoints = state.stop_points.map((s) => {
        if (String(s.position) == action.position) {
          return _.assign({}, s, {checked : !s.checked})
        }else {
          return s
        }
      })
      return _.assign({}, state, {stop_points: updatedStopPoints})
    default:
      return state
  }
}

export default function journeyPatterns (state = [], action)  {
  switch (action.type) {
    case 'RECEIVE_JOURNEY_PATTERNS':
      return [...action.json]
    case 'RECEIVE_ERRORS':
      return [...action.json]
    case 'RECEIVE_ROUTE_COSTS':
      return state.map((j, i) =>{
        if(i == action.index) {
          const new_costs = Object.assign({}, j.costs)
          new_costs[action.key] = action.costs[action.key] ||
            {distance: 0, time: 0}
          return _.assign({}, j, {costs: new_costs})
        } else {
          return j
        }
      })
    case 'GO_TO_PREVIOUS_PAGE':
      $('#ConfirmModal').modal('hide')
      if(action.pagination.page > 1){
        actions.fetchJourneyPatterns(action.dispatch, action.pagination.page, action.nextPage)
      }
      return state
    case 'GO_TO_NEXT_PAGE':
      $('#ConfirmModal').modal('hide')
      if (action.pagination.totalCount - (action.pagination.page * action.pagination.perPage) > 0){
        actions.fetchJourneyPatterns(action.dispatch, action.pagination.page, action.nextPage)
      }
      return state
    case 'UPDATE_CHECKBOX_VALUE':
      return state.map((j, i) =>{
        if(i == action.index) {
          return journeyPattern(j, action)
        } else {
          return j
        }
      })
    case 'DELETE_JOURNEYPATTERN':
      return state.map((j, i) =>{
        if(i == action.index) {
          return _.assign({}, j, {deletable: true})
        } else {
          return j
        }
      })
    case 'UPDATE_JOURNEYPATTERN_COSTS':
      return state.map((j, i) =>{
        if(i == action.index) {
          const new_costs = Object.assign({}, j.costs)
          Object.keys(action.costs).map((key) => {
            let new_costs_for_key = Object.assign({}, j.costs[key] || {}, action.costs[key])
            new_costs[key] = new_costs_for_key
          })
          return _.assign({}, j, {costs: new_costs})
        } else {
          return j
        }
      })
    case 'ADD_JOURNEYPATTERN':
      return [
        journeyPattern(state, action),
        ...state
      ]
    case 'SAVE_MODAL':
      return state.map((j, i) =>{
        if(i == action.index) {
          return _.assign({}, j, {
            name: action.data.name.value,
            published_name: action.data.published_name.value,
            registration_number: action.data.registration_number.value,
            custom_fields: action.data.custom_fields,
            shape: action.data.shape
          })
        } else {
          return j
        }
      })
    default:
      return state
  }
}
