export default class RouteFormHelper {
  constructor(props) {
    this.inputIds = props.inputIds
    this.stopPoints = props.stopPoints
    this.errors = {
      inputs: false,
      stopPointsLength: false,
      emptyStopPoint: false
    }
    this.stopPointIds = {
      lengthId: 'not_enough_stop_points',
      emptyId: 'empty_stop_point'
    }
  }

  // Getters
  get blankInputIds() {
    return this.inputIds.filter( id => $(id).val() == "" )
  }

  get filledInputIds() {
    return this.inputIds.filter( id => $(id).val() != "" )
  }

  get blankStopPointInputs() {
    return $("select[id*='route_stop_point']")
  }

  get hasErrors() {
    return this.errors.inputs || this.errors.stopPointsLength || this.errors.emptyStopPoint
  }

  // Event Listeners 
  handleSubmit(event) {
    this.handleFilledInputs()
    this.handleBlankInputs()
    this.handleStopPoints()

    if (this.hasErrors) {
      event.preventDefault()
    } else {
      this.stopPoints.forEach((stopPoint, i) => this.addStopPoint(stopPoint, i))
      console.log('prout')
    }
  }

  // Handlers
  handleFilledInputs() {
    this.filledInputIds.forEach(id => {
      $(id).parents('.form-group').removeClass('has-error')
      $(id).siblings('span').remove()
    })
  }

  handleBlankInputs() {
    let ids = this.blankInputIds

    if (ids.length > 0 ) {
      this.errors.inputs = true
      ids.forEach( id => {
        if (!$(id).parents('.form-group').hasClass('has-error')) {
          $(id).parents('.form-group').addClass('has-error')
          $(id).parent().append(`<span class='help-block small'>${'doit être rempli(e)'}</span>`)
        }
      })
    } else {
      this.errors.inputs = false
    }
  }

  handleStopPoints() {
    const { lengthId, emptyId } = this.stopPointIds
    let $lengthError = $(`#${lengthId}`)
    let $emptyError = $(`#${emptyId}`)

    // Route length validation
    if (this.stopPoints.length >= 2) {
      this.cleanStopPointError($lengthError, 'stopPointsLength')
    }
    else {
      this.handleStopPointError($lengthError, lengthId, 'stopPointsLength')
    }

    // Check if route has empty stop points
    if (this.blankStopPointInputs.length > 0) {
      this.handleStopPointError($emptyError, emptyId, 'emptyStopPoint')
    } else {
      this.cleanStopPointError($emptyError, 'emptyStopPoint')
    }
  }

  handleStopPointError (el, id, key) {
    this.errors[key] = true
    if (el.length == 0) {
      let msg = I18n.t(`activerecord.errors.models.route.attributes.stop_points.${id}`)
      $('#stop_points').find('.subform').after(`<div id='${id}' class='alert alert-danger'><span class='fa fa-lg fa-exclamation-circle'></span><span>${msg}</span></div>`)
    }
  }

  // Event Handlers

  onDeleteStopPoint(index) {
    let stopPoint = this.stopPoints[index]

    if (stopPoint.stoppoint_id !== undefined) {
      let now = Date.now()
      this.addInput('id', stopPoint.stoppoint_id, now)
      this.addInput('_destroy', 'true', now)
    }
  }

  cleanStopPointError(el, key) {
    this.errors[key] = false
    if (el.length > 0) el.remove()
  }

  addStopPoint(stopPoint, index) {
    this.addInput('id', stopPoint.stoppoint_id || '', index)
    this.addInput('stop_area_id', stopPoint.stoparea_id, index)
    this.addInput('position', stopPoint.index, index)
    this.addInput('for_boarding', stopPoint.for_boarding, index)
    this.addInput('for_alighting', stopPoint.for_alighting, index)
  }

  addInput(name, value, index) {
    let form = document.getElementById('route_form')
    let input = document.createElement('input')
    let formatedName = `route[stop_points_attributes][${index.toString()}][${name}]`
    input.setAttribute('type', 'hidden')
    input.setAttribute('name', formatedName)
    input.setAttribute('value', value)
    form.appendChild(input)
  }
}
