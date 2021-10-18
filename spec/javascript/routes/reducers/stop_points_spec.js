import stopPointsReducer from '../../../../app/packs/src/routes/reducers/stopPoints'
import { receivedRoute } from '../helpers'
import _ from 'lodash'

 //  _  _ ___ _    ___ ___ ___  ___
 // | || | __| |  | _ \ __| _ \/ __|
 // | __ | _|| |__|  _/ _||   /\__ \
 // |_||_|___|____|_| |___|_|_\|___/
 //

let state = []

let fakeData = {
  geometry: undefined,
  registration_number: 'rn_test',
  stoparea_id: 'sid_test',
  text: 't_test',
  user_objectid: 'uoid_test'
}

let update_stop_point = (stop_point, opts) => {
  return _.assign({}, stop_point, opts)
}

let stop_point = (opts) => {
  return _.assign({},
    {
      text: "",
      index: 0,
      edit: false,
      for_boarding: 'normal',
      for_alighting: 'normal',
      stoparea_kind: undefined,
      olMap: { isOpened: false, json: {} }
    },
    opts
  )
}

let stop_point_1 = stop_point({text: 'first',  index: 0, stoppoint_id: 72 })
let stop_point_2 = stop_point({text: 'second', index: 1, stoppoint_id: 73 })
let stop_point_3 = stop_point({text: 'third',  index: 2, stoppoint_id: 74 })

let it_should_handle = (action, final_state, custom_state=null) => {
  it("should handle "+ action.type, () => {
    expect(
      stopPointsReducer(custom_state || state, action)
    ).toEqual( final_state )
  })
}


 //  ___ ___ ___ ___ ___
 // / __| _ \ __/ __/ __|
 // \__ \  _/ _| (__\__ \
 // |___/_| |___\___|___/
 //


describe('stops reducer', () => {
  beforeEach(()=>{
    state = [ stop_point_1, stop_point_2, stop_point_3 ]
  })

  it('should return the initial state', () => {
    expect(
      stopPointsReducer(undefined, {})
    ).toEqual([])
  })

  it_should_handle(
    {type: "ADD_STOP"},
    [stop_point_1, stop_point_2, stop_point_3, stop_point({index: 3, edit: true})]
  )

  it_should_handle(
    {type: 'MOVE_STOP_UP', index: 1},
    [ update_stop_point(stop_point_2, {index: 0}), update_stop_point(stop_point_1, {index: 1}), stop_point_3 ]
  )

  it_should_handle(
    {type: 'MOVE_STOP_DOWN', index: 0},
    [ update_stop_point(stop_point_2, {index: 0}), update_stop_point(stop_point_1, {index: 1}), stop_point_3 ]
  )

  it_should_handle(
    {type: 'DELETE_STOP', index: 1},
    [stop_point_1, stop_point_3]
  )

  let text = {
    text: "new value",
    name: 'new',
    stoparea_id: 1,
    user_objectid: "1234",
    longitude: 123,
    latitude: 123,
    registration_number: '0',
    city_name: 'city',
    area_type: 'area',
    short_name: 'new',
    stoparea_kind: 'commercial',
    comment: 'newcomment'
  }
  it_should_handle(
    {type: 'UPDATE_INPUT_VALUE', index: 0, text: text},
    [
      update_stop_point(stop_point_1, text),
      stop_point_2,
      stop_point_3
    ]
  )

  text = {
    text: "new value",
    name: 'new',
    stoparea_id: 1,
    user_objectid: "1234",
    longitude: 123,
    latitude: 123,
    registration_number: '0',
    city_name: 'city',
    area_type: 'area',
    short_name: 'new',
    stoparea_kind: 'non_commercial',
    comment: 'newcomment'
  }
  let res = update_stop_point(stop_point_1, text)
  res  = update_stop_point(res, {for_boarding: "forbidden", for_alighting: "forbidden"})
  it_should_handle(
    {type: 'UPDATE_INPUT_VALUE', index: 0, text: text},
    [
      res,
      stop_point_2,
      stop_point_3
    ]
  )

  it_should_handle(
    {type: 'UPDATE_SELECT_VALUE', index: 0, select_id: 'for_boarding', select_value: 'prohibited'},
    [
      update_stop_point(stop_point_1, {for_boarding: 'prohibited'}),
      stop_point_2,
      stop_point_3
    ]
  )

  it_should_handle(
    {type: 'TOGGLE_MAP', index: 0},
    [
      update_stop_point(stop_point_1, {olMap: {
        isOpened: true,
        json: {
          text: 'first',
          index: 0,
          stoppoint_id: 72,
          edit: false,
          for_boarding: 'normal',
          for_alighting: 'normal',
          olMap: undefined
        }
      }}),
      stop_point_2,
      stop_point_3
    ]
  )

  it_should_handle(
    {type: 'TOGGLE_EDIT', index: 0},
    [
      update_stop_point(stop_point_1, {edit: true}),
      stop_point_2,
      stop_point_3
    ]
  )

  let openedMapState = [
    update_stop_point(stop_point_1, {
      olMap: {
        isOpened: true,
        json: {}
      }
    }),
    stop_point_2,
    stop_point_3
  ]

  it_should_handle(
    {type: 'SELECT_MARKER', index: 0, data: fakeData},
    [
      update_stop_point(stop_point_1, {
        olMap: {
          isOpened: true,
          json: fakeData
        }
      }),
      stop_point_2,
      stop_point_3
    ],
    openedMapState
  )

  it_should_handle(
    {type: 'UNSELECT_MARKER', index: 0},
    [
      update_stop_point(stop_point_1, {
        olMap: {
          isOpened: true,
          json: {}
        }
      }),
      stop_point_2,
      stop_point_3
    ],
    openedMapState
  )

  it_should_handle(
    { type: 'RECEIVE_ROUTE', json: receivedRoute },
    receivedRoute['stop_points']
  )
})
