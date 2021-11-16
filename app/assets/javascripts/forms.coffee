# IE fix
isIE = false || !!document.documentMode
isEdge = !isIE && !!window.StyleMedia

@togglableFilter = ->
  $('.form-filter').on 'click', '.form-group.togglable', (e)->
    if $(e.target).hasClass('togglable') || $(e.target).parent().hasClass('togglable')
      $(this).siblings().removeClass 'open'
      $(this).toggleClass 'open'

@switchInput = ->
  $('.form-group.has_switch').each ->
    labelCont = $(this).find('.switch-label')

    if labelCont.text() == ''
      labelCont.text(labelCont.data('uncheckedvalue'))

    $(this).on 'click', "input[type='checkbox']", ->
      if labelCont.text() == labelCont.data('checkedvalue')
        labelCont.text(labelCont.data('uncheckedvalue'))
      else
        labelCont.text(labelCont.data('checkedvalue'))

@submitMover = ->
  $('.formSubmitr').appendTo('.page-action').addClass('sticky-action')

  if isIE || isEdge
    $('.formSubmitr').off()

@colorSelector = ->
  $('.form-group .dropdown.color_selector').each ->
    selectedStatusColor = $(this).children('.dropdown-toggle').children('.fa-circle, .fa-font')
    selectedStatusLabel = $(this).children('.dropdown-toggle')
    self = this
    $(this).on 'click', "input[type='radio']", (e) ->
      selectedValue = e.currentTarget.value
      selectedText = $(e.currentTarget).parent()[0].textContent
      if e.currentTarget.getAttribute("data-for")
        hidden = $("[name=\"#{e.currentTarget.getAttribute("data-for")}\"]")

      if selectedValue == ''
        $(selectedStatusColor).css('color', 'transparent')
        $(selectedStatusLabel).contents().filter( -> this.nodeType == 3 ).filter(':first').text = ""
        hidden?.val ""
      else
        actualColor = selectedValue
        actualColor = "##{actualColor}" if selectedValue[0] != "#"

        $(selectedStatusColor).css('color', actualColor)
        $(selectedStatusLabel).contents().filter( -> this.nodeType == 3 ).first().replaceWith selectedText
        hidden?.val selectedValue

      $(self).find('.dropdown-toggle').click()

$ ->
  togglableFilter()
  submitMover()
  switchInput()
  colorSelector()
  $(document).on 'submitMover', (e) ->
    submitMover()

if isIE || isEdge
  $(document).on 'click', '.formSubmitr', (e)->
    e.preventDefault()
    target = $(this).attr('form')
    $('#' + target).submit()
