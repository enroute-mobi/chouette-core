import { SUBMIT_ROUTE_SUCCESS, SUBMIT_ROUTES_ERROR } from './route'

export const initialState = {
  route: {
    name: false,
  },
  stopPoints: {
    invalidLength: false,
    invalidStopPointIndexes: []
  }
}

// Reducer
const formErrors = (state = initialState, action) => {
  switch (action.type) {
    case 'VALIDATE_FIELD':
      const { category, value } = action
      const newError = Object.assign({}, state[category], action.value)
      return Object.assign({}, state, { [category]: newError })
    default:
      return state
  }
}

export const handleFormValidation = category => key => errorValue => ({
  category,
  [key]: errorValue
})

export default formErrors