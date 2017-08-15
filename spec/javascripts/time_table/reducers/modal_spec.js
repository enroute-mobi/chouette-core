var modalReducer = require('es6_browserified/time_tables/reducers/modal')

let state = {}

describe('modal reducer', () => {
  beforeEach(() => {
    state = {
      confirmModal: {},
      modalProps: {
        active: false,
        begin: {
          day: '01',
          month: '01',
          year: String(new Date().getFullYear())
        },
        end: {
          day: '01',
          month: '01',
          year: String(new Date().getFullYear())
        },
        index: false,
        error: ''
      },
      type: ""
    }
  })

  it('should return the initial state', () => {
    expect(
      modalReducer(undefined, {})
    ).toEqual({})
  })

  it('should handle OPEN_CONFIRM_MODAL', () => {
    let callback = function(){}
    expect(
      modalReducer(state, {
        type: 'OPEN_CONFIRM_MODAL',
        callback
      })
    ).toEqual(Object.assign({}, state, {type: "confirm", confirmModal: { callback: callback }}))
  })

  it('should handle CLOSE_PERIOD_FORM', () => {
    let newModalProps = Object.assign({}, state.modalProps, {active: false})
    expect(
      modalReducer(state, {
        type: 'CLOSE_PERIOD_FORM'
      })
    ).toEqual(Object.assign({}, state, {modalProps: newModalProps}))
  })

  it('should handle OPEN_EDIT_PERIOD_FORM', () => {
    let period = {
      id : 1,
      period_end : "2017-03-05",
      period_start : "2017-02-23"
    }
    let period_start = period.period_start.split('-')
    let period_end = period.period_end.split('-')

    let index = 1

    let newModalProps = {
      active: true,
      begin: {
        day: period_start[2],
        month: period_start[1],
        year: period_start[0]
      },
      end: {
        day: period_end[2],
        month: period_end[1],
        year: period_end[0]
      },
      index: index,
      error: ''
    }
    expect(
      modalReducer(state, {
        type: 'OPEN_EDIT_PERIOD_FORM',
        period,
        index
      })
    ).toEqual(Object.assign({}, state, {modalProps: newModalProps}))
  })

  it('should handle OPEN_ADD_PERIOD_FORM', () => {
    let emptyDate = {
      day: '01',
      month: '01',
      year: String(new Date().getFullYear())
    }
    let newModalProps = Object.assign({}, state.modalProps, {
      active: true,
      begin: emptyDate,
      end: emptyDate,
      index: false,
      error: ""
    })

    expect(
      modalReducer(state, {
        type: 'OPEN_ADD_PERIOD_FORM'
      })
    ).toEqual(Object.assign({}, state, {modalProps: newModalProps}))
  })

  it('should handle UPDATE_PERIOD_FORM', () => {
    let val = "11"
    let group = "begin"
    let selectType = "day"

    let newModalProps = {
      active: false,
      begin: {
        day: val,
        month: '01',
        year: String(new Date().getFullYear())
      },
      end: {
        day: '01',
        month: '01',
        year: String(new Date().getFullYear())
      },
      index: false,
      error: ''
    }

    expect(
      modalReducer(state, {
        type: 'UPDATE_PERIOD_FORM',
        val,
        group,
        selectType
      })
    ).toEqual(Object.assign({}, state, {modalProps: newModalProps}))
  })

  it('should handle VALIDATE_PERIOD_FORM and throw error if period starts after the end', () => {
    let modProps = {
      active: false,
      begin: {
        day: '13',
        month: '01',
        year: String(new Date().getFullYear())
      },
      end: {
        day: '01',
        month: '01',
        year: String(new Date().getFullYear())
      },
      index: false,
      error: ''
    }
    let newModalProps = {
      active: false,
      begin: {
        day: '01',
        month: '01',
        year: String(new Date().getFullYear())
      },
      end: {
        day: '01',
        month: '01',
        year: String(new Date().getFullYear())
      },
      index: false,
      error: 'La date de départ doit être antérieure à la date de fin'
    }

    let ttperiods = []
    let ttdates = []

    expect(
      modalReducer(state, {
        type: 'VALIDATE_PERIOD_FORM',
        modalProps : modProps,
        timeTablePeriods: ttperiods,
        timetableInDates: ttdates
      })
    ).toEqual(Object.assign({}, state, {modalProps: newModalProps}))
  })

  it('should handle VALIDATE_PERIOD_FORM and throw error if periods overlap', () => {
    let state2 = {
      confirmModal: {},
      modalProps: {
        active: false,
        begin: {
          day: '03',
          month: '05',
          year: '2017'
        },
        end: {
          day: '09',
          month: '05',
          year: '2017'
        },
        index: false,
        error: ''
      },
      type: ''
    }
    let modProps2 = {
      active: false,
      begin: {
        day: '03',
        month: '05',
        year: '2017'
      },
      end: {
        day: '09',
        month: '05',
        year: '2017'
      },
      index: false,
      error: ''
    }
    let ttperiods2 = [
      {id: 261, period_start: '2017-02-23', period_end: '2017-03-05'},
      {id: 262, period_start: '2017-03-15', period_end: '2017-03-25'},
      {id: 264, period_start: '2017-04-24', period_end: '2017-05-04'},
      {id: 265, period_start: '2017-05-14', period_end: '2017-05-24'}
    ]

    let ttdates2 = []

    let newModalProps2 = {
      active: true,
      begin: {
        day: '03',
        month: '05',
        year: '2017'
      },
      end: {
        day: '09',
        month: '05',
        year: '2017'
      },
      index: false,
      error: "Les périodes ne peuvent pas se chevaucher"
    }

    expect(
      modalReducer(state2, {
        type: 'VALIDATE_PERIOD_FORM',
        modalProps : modProps2,
        timeTablePeriods: ttperiods2,
        timetableInDates: ttdates2
      })
    ).toEqual(Object.assign({}, state2, {modalProps: newModalProps2}))
  })

  it('should handle VALIDATE_PERIOD_FORM and throw error if period overlaps date', () => {
    let state3 = {
      confirmModal: {},
      modalProps: {
        active: false,
        begin: {
          day: '01',
          month: '08',
          year: '2017'
        },
        end: {
          day: '09',
          month: '08',
          year: '2017'
        },
        index: false,
        error: ''
      },
      type: ''
    }
    let modProps3 = {
      active: false,
      begin: {
        day: '01',
        month: '08',
        year: '2017'
      },
      end: {
        day: '09',
        month: '08',
        year: '2017'
      },
      index: false,
      error: ''
    }
    let ttperiods3 = []

    let ttdates3 = [{date: "2017-08-04", include_date: true}]

    let newModalProps3 = {
      active: true,
      begin: {
        day: '01',
        month: '08',
        year: '2017'
      },
      end: {
        day: '09',
        month: '08',
        year: '2017'
      },
      index: false,
      error: "Une période ne peut chevaucher une date dans un calendrier"
    }

    expect(
      modalReducer(state3, {
        type: 'VALIDATE_PERIOD_FORM',
        modalProps : modProps3,
        timeTablePeriods: ttperiods3,
        timetableInDates: ttdates3
      })
    ).toEqual(Object.assign({}, state3, {modalProps: newModalProps3}))
  })
})
