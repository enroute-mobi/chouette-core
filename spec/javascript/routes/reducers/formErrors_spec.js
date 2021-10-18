import formErrorsReducer, { handleFormValidation, initialState } from '../../../../app/packs/src/routes/reducers/formErrors'
import { actionHandler } from '../helpers'

let newError, category, value

const it_should_handle = actionHandler(formErrorsReducer)(initialState)

describe('formErrors reducer', () => {
  it('should return the initial state', () => {
    expect(
      formErrorsReducer(undefined, {})
    ).toEqual(initialState)
  })

  describe('With invalid field', () => {
    const { category, ...value } = handleFormValidation('stopPoints')('invalidLength')(true)
    const newError = Object.assign({}, initialState[category], value)
    it_should_handle(
      { type: "VALIDATE_FIELD", category, value },
      Object.assign({}, initialState, { [category]: newError })
    )
  })

  describe('With valid field', () => {
    const { category, ...value } = handleFormValidation('stopPoints')('invalidLength')(false)
    const newError = Object.assign({}, initialState[category], value)

    it_should_handle(
      { type: "VALIDATE_FIELD", category, value },
      Object.assign({}, initialState, { [category]: newError })
    )
  })
})