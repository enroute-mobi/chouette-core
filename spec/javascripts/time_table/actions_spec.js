var actions = require('es6_browserified/time_tables/actions')
const dispatch = function(){}
const dayTypes = [true, true, true, true, true, true, true]
const day = {
  date : "2017-05-01",
  day : "lundi",
  excluded_date : false,
  in_periods : true,
  include_date : false,
  mday : 1,
  wday : 1,
  wnumber : "18"
}
describe('actions', () => {
  it('should create an action to update dayTypes', () => {
    let obj = {}
    const expectedAction = {
      type: 'UPDATE_DAY_TYPES',
      dayTypes: obj
    }
    expect(actions.updateDayTypes(obj)).toEqual(expectedAction)
  })

  it('should create an action to update comment', () => {
    const expectedAction = {
      type: 'UPDATE_COMMENT',
      comment: 'test'
    }
    expect(actions.updateComment('test')).toEqual(expectedAction)
  })

  it('should create an action to update color', () => {
    const expectedAction = {
      type: 'UPDATE_COLOR',
      color: '#ffffff'
    }
    expect(actions.updateColor('#ffffff')).toEqual(expectedAction)
  })

  it('should create an action to update selected tags', () => {
    let selectedItem = {
      id: 1,
      name: 'test'
    }
    const expectedAction = {
      type: 'UPDATE_SELECT_TAG',
      selectedItem: selectedItem
    }
    expect(actions.select2Tags(selectedItem)).toEqual(expectedAction)
  })

  it('should create an action to update unselected tags', () => {
    let selectedItem = {
      id: 1,
      name: 'test'
    }
    const expectedAction = {
      type: 'UPDATE_UNSELECT_TAG',
      selectedItem: selectedItem
    }
    expect(actions.unselect2Tags(selectedItem)).toEqual(expectedAction)
  })


  it('should create an action to go to previous page', () => {
    let pagination = {
      currentPage: '2017-01-01',
      periode_range: [],
      stateChanged: false
    }
    const expectedAction = {
      type: 'GO_TO_PREVIOUS_PAGE',
      dispatch,
      pagination,
      nextPage: false
    }
    expect(actions.goToPreviousPage(dispatch, pagination)).toEqual(expectedAction)
  })

  it('should create an action to go to next page', () => {
    let pagination = {
      currentPage: '2017-01-01',
      periode_range: [],
      stateChanged: false
    }
    const expectedAction = {
      type: 'GO_TO_NEXT_PAGE',
      dispatch,
      pagination,
      nextPage: true
    }
    expect(actions.goToNextPage(dispatch, pagination)).toEqual(expectedAction)
  })

  it('should create an action to change page', () => {
    let page = '2017-05-04'
    const expectedAction = {
      type: 'CHANGE_PAGE',
      dispatch,
      page: page
    }
    expect(actions.changePage(dispatch, page)).toEqual(expectedAction)
  })

  it('should create an action to delete period', () => {
    let index = 1
    const expectedAction = {
      type: 'DELETE_PERIOD',
      index,
      dayTypes
    }
    expect(actions.deletePeriod(index, dayTypes)).toEqual(expectedAction)
  })

  it('should create an action to open add period form', () => {
    const expectedAction = {
      type: 'OPEN_ADD_PERIOD_FORM',
    }
    expect(actions.openAddPeriodForm()).toEqual(expectedAction)
  })

  it('should create an action to open edit period form', () => {
    let period = {
      id : 1,
      period_end : "2017-03-05",
      period_start : "2017-02-23"
    }
    let index = 1
    const expectedAction = {
      type: 'OPEN_EDIT_PERIOD_FORM',
      period,
      index
    }
    expect(actions.openEditPeriodForm(period, index)).toEqual(expectedAction)
  })

  it('should create an action to close period form', () => {
    const expectedAction = {
      type: 'CLOSE_PERIOD_FORM',
    }
    expect(actions.closePeriodForm()).toEqual(expectedAction)
  })

  it('should create an action to update period form', () => {
    let val = "11"
    let group = "start"
    let selectType = "day"
    const expectedAction = {
      type: 'UPDATE_PERIOD_FORM',
      val,
      group,
      selectType
    }
    expect(actions.updatePeriodForm(val, group, selectType)).toEqual(expectedAction)
  })

  it('should create an action to validate period form', () => {
    let modalProps = {}
    let timeTablePeriods = []
    let metas = {}
    let currentMonthDaysIn = []
    const expectedAction = {
      type: 'VALIDATE_PERIOD_FORM',
      modalProps,
      timeTablePeriods,
      metas,
      currentMonthDaysIn
    }
    expect(actions.validatePeriodForm(modalProps, timeTablePeriods, metas, currentMonthDaysIn)).toEqual(expectedAction)
  })

  it('should create an action to include date in period', () => {
    let index = 1
    const expectedAction = {
      type: 'INCLUDE_DATE_IN_PERIOD',
      index,
      dayTypes
    }
    expect(actions.includeDateInPeriod(index, dayTypes)).toEqual(expectedAction)
  })

  it('should create an action to exclude date from period', () => {
    let index = 1
    const expectedAction = {
      type: 'EXCLUDE_DATE_FROM_PERIOD',
      index,
      dayTypes
    }
    expect(actions.excludeDateFromPeriod(index, dayTypes)).toEqual(expectedAction)
  })

  it('should create an action to open confirm modal', () => {
    let callback = function(){}
    const expectedAction = {
      type: 'OPEN_CONFIRM_MODAL',
      callback
    }
    expect(actions.openConfirmModal(callback)).toEqual(expectedAction)
  })

  it('should create an action to close modal', () => {
    const expectedAction = {
      type: 'CLOSE_MODAL',
    }
    expect(actions.closeModal()).toEqual(expectedAction)
  })

})
