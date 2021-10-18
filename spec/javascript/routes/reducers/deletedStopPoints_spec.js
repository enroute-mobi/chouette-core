import deletedStopPointsReducer from '../../../../app/packs/src/routes/reducers/deletedStopPoints'
import { actionHandler } from '../helpers'
import _ from 'lodash'

const it_should_handle = actionHandler(deletedStopPointsReducer)([])

describe('deletedStopPoints reducer', () => {
  it('should return the initial state', () => {
    expect(
      deletedStopPointsReducer(undefined, [])
    ).toEqual([])
  })

  describe('DELETE_STOP', () => {
    describe('when stop point is persisted', () => {
      it_should_handle(
        { type: "DELETE_STOP", index: 0, stopPointId: 1 },
        [{ id: 1, _destroy: true }]
      )
    })

    describe('when stop point is not persisted', () => {
      it_should_handle(
        { type: "DELETE_STOP", index: 0 },
        []
      )
    })

    describe('when stop point is already in state', () => {
      it_should_handle(
        { type: "DELETE_STOP", index: 0, stopPointId: 1 },
        [{ id: 1, _destroy: true }],
        [{ id: 1, _destroy: true }]
      )
    })
  })
})