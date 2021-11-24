const actions = {
  enterEditMode: () => ({
    type: "ENTER_EDIT_MODE"
  }),
  exitEditMode: () => ({
    type: "EXIT_EDIT_MODE"
  }),
  receiveJourneyPatterns : (json) => ({
    type: "RECEIVE_JOURNEY_PATTERNS",
    json
  }),
  receiveErrors : (json) => ({
    type: "RECEIVE_ERRORS",
    json
  }),
  receiveRouteCosts: (costs, key, index) => ({
    type: "RECEIVE_ROUTE_COSTS",
    costs,
    key,
    index
  }),
  unavailableServer : () => ({
    type: 'UNAVAILABLE_SERVER'
  }),
  goToPreviousPage : (dispatch, pagination) => ({
    type: 'GO_TO_PREVIOUS_PAGE',
    dispatch,
    pagination,
    nextPage : false
  }),
  goToNextPage : (dispatch, pagination) => ({
    type: 'GO_TO_NEXT_PAGE',
    dispatch,
    pagination,
    nextPage : true
  }),
  updateCheckboxValue : (e, index) => ({
    type : 'UPDATE_CHECKBOX_VALUE',
    position : e.currentTarget.id,
    index
  }),
  checkConfirmModal : (event, callback, stateChanged,dispatch) => {
    if(stateChanged === true){
      return actions.openConfirmModal(callback)
    }else{
      dispatch(actions.fetchingApi())
      return callback
    }
  },
  openConfirmModal : (callback) => ({
    type : 'OPEN_CONFIRM_MODAL',
    callback
  }),
  openEditModal : (index, journeyPattern) => ({
    type : 'EDIT_JOURNEYPATTERN_MODAL',
    index,
    journeyPattern
  }),
  openCreateModal : () => ({
    type : 'CREATE_JOURNEYPATTERN_MODAL'
  }),
  deleteJourneyPattern : (index) => ({
    type : 'DELETE_JOURNEYPATTERN',
    index,
  }),
  updateJourneyPatternCosts : (index, costs) => ({
    type : 'UPDATE_JOURNEYPATTERN_COSTS',
    index,
    costs
  }),
  closeModal : () => ({
    type : 'CLOSE_MODAL'
  }),
  saveModal : (index, data) => ({
    type: 'SAVE_MODAL',
    data,
    index
  }),
  addJourneyPattern : (data) => ({
    type: 'ADD_JOURNEYPATTERN',
    data,
  }),
  savePage : (dispatch, currentPage) => ({
    type: 'SAVE_PAGE',
    dispatch
  }),
  updateTotalCount: (diff) => ({
    type: 'UPDATE_TOTAL_COUNT',
    diff
  }),
  fetchingApi: () =>({
      type: 'FETCH_API'
  }),
  duplicateJourneyPattern: () => ({
    type: 'DUPLICATE_JOURNEY_PATTERN'
  }),
  selectShape: selectedItem => ({
    type: 'SELECT_SHAPE_EDIT_MODAL',
    selectedItem
  }),
  unselectShape: () => ({
    type: 'UNSELECT_SHAPE_EDIT_MODAL',
  }),
  resetValidation: (target) => {
    $(target).parent().removeClass('has-error').children('.help-block').remove()
  },
  validateFields : (fields) => {
    const test = []

    Object.keys(fields).map(function(key) {
      test.push(fields[key].validity.valid)
    })
    if(test.indexOf(false) >= 0) {
      // Form is invalid
      test.map(function(item, i) {
        if(item == false) {
          const k = Object.keys(fields)[i]
          $(fields[k]).parent().addClass('has-error').children('.help-block').remove()
          $(fields[k]).parent().append("<span class='small help-block'>" + fields[k].validationMessage + "</span>")
        }
      })
      return false
    } else {
      // Form is valid
      return true
    }
  },
  submitJourneyPattern : (dispatch, state, next) => {
    dispatch(actions.fetchingApi())
    let urlJSON = window.location.pathname + ".json"
    let hasError = false
    fetch(urlJSON, {
      credentials: 'same-origin',
      method: 'PATCH',
      contentType: 'application/json; charset=utf-8',
      Accept: 'application/json',
      body: JSON.stringify(state),
      headers: {
        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
      }
    }).then(response => {
        if(!response.ok) {
          hasError = true
        }
        return response.json()
      }).then((json) => {
        if(hasError == true) {
          dispatch(actions.receiveErrors(json))
        } else {
          if(next) {
            dispatch(next)
          } else {
            if(json.length != window.currentItemsLength){
              dispatch(actions.updateTotalCount(window.currentItemsLength - json.length))
            }
            window.currentItemsLength = json.length
            dispatch(actions.exitEditMode())
            dispatch(actions.receiveJourneyPatterns(json))
          }
        }
      })
  },
  fetchJourneyPatterns : (dispatch, currentPage, nextPage) => {
    if(currentPage == undefined){
      currentPage = 1
    }
    let journeyPatterns = []
    let page

    switch (nextPage) {
      case true:
        page = currentPage + 1
        break
      case false:
        if(currentPage > 1){
          page = currentPage - 1
        }
        break
      default:
        page = currentPage
        break
    }
    let str = ".json"
    if(page > 1){
      str = '.json?page=' + page.toString()
    }
    let urlJSON = window.location.pathname + str
    let hasError = false
  
    return fetch(urlJSON, {
      credentials: 'same-origin',
    }).then(response => {
        if(response.status == 500) {
          hasError = true
        }
        return response.json()
      }).then((json) => {
        if(hasError == true) {
          dispatch(actions.unavailableServer())
        } else {
          if(json.length != 0){
            let j = 0
            while(j < json.length){
              let val = json[j]
              let i = 0
              while(i < val.route_short_description.stop_points.length){
                let stop_point = val.route_short_description.stop_points[i]
                stop_point.checked = false
                val.stop_area_short_descriptions.map((element) => {
                  if(element.stop_area_short_description.position === stop_point.position){
                    stop_point.checked = true
                  }
                })
                i ++
              }
              journeyPatterns.push(
                _.assign({}, val, {
                  stop_points: val.route_short_description.stop_points,
                  costs: val.costs || {},
                  deletable: false
                })
              )
              j ++
            }
          }
          window.currentItemsLength = journeyPatterns.length
          dispatch(actions.receiveJourneyPatterns(journeyPatterns))
        }
      })
  },
  fetchRouteCosts: (dispatch, key, index) => {
    if(actions.fetchingRouteCosts){
        // A request is already sent, wait for it
        if(!actions.waitingForRouteCosts){
          actions.waitingForRouteCosts = []
        }
        actions.waitingForRouteCosts.push([key, index])
        return
    }

    if(actions.routeCostsCache) {
      // Dispatch asynchronously to prevent warning when
      // this executes during `render()`
      requestAnimationFrame(() => {
        dispatch(actions.receiveRouteCosts(
          actions.routeCostsCache,
          key,
          index
        ))
      })
    } else {
      actions.fetchingRouteCosts = true
      fetch(window.routeCostsUrl, {
        credentials: 'same-origin',
      }).then(response => {
        return response.json()
      }).then(json => {
        let costs = json.costs ? json.costs : {}
        actions.routeCostsCache = costs

        dispatch(actions.receiveRouteCosts(costs, key, index))
        if(actions.waitingForRouteCosts){
          actions.waitingForRouteCosts.map(function(item, i) {
            dispatch(actions.receiveRouteCosts(costs, item[0], item[1]))
          })
        }
        actions.fetchingRouteCosts = false
      })
    }
  },
  getChecked : (jp) => {
    return jp.filter((obj) => {
      return obj.checked
    })
  }
}

export default actions
