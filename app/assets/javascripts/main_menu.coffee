
stickyActions = []
ptitleCont = ""

@handleOpenMenu = ->
  $('#main_nav').find('.openMenu').on 'click', (e) ->
    $(this).parent().addClass 'open'

@handleCloseMenu = ->
  closeMenu = ->
    $('#menu_left.nav-menu').removeClass 'open'
    
  $('#main_nav').find('.closeMenu').on 'click', (e) ->
    closeMenu()

  $(document).on 'keyup', (e) ->
    if $('#main_nav').find('.closeMenu').length == 1 && e.keyCode == 27
      closeMenu()

  $(document).on 'click', (e) ->
    unless $('#main_nav').is(e.target) || $('#main_nav').has(e.target).length > 0
      closeMenu()

@handleResetMenu = ->
  $(document).on 'page:before-change', ->
    stickyActions = []
    ptitleCont = ""

@handleOpenMenuPanel = ->
  selectedItem = $('#main_nav').find('.active')
  selectedItem.closest('.panel-collapse').addClass 'in'
  selectedItem.closest('.panel-title').children('a').attr('aria-expanded') == true

@sticker = ->
  # Sticky behavior
  $(document).on 'scroll', () ->
    limit = 51
    offset = 30

    if $(window).scrollTop() >= limit + offset
      if stickyActions.length == 0
        if ($('.page-action .small').length > 0)
          stickyActions.push
            content: [
              $('.page-action .small'),
              $('.page-action .small').first().next()
              ]
            originalParent: $('.page-action .small').parent()

        for action in $(".sticky-action, .sticky-actions")
          stickyActions.push
            class: "small",
            content: [$(action)]
            originalParent: $(action).parent()

      if $(".page-title").length > 0
        ptitleCont = $(".page-title").html()

      stickyContent = $('<div class="sticky-content"></div>')
      stickyContent.append $("<div class='sticky-ptitle'>#{ptitleCont}</div>")
      stickyContent.append $('<div class="sticky-paction"></div>')
      $('#main_nav').addClass 'sticky'

      if $('#menu_top').find('.sticky-content').length == 0
        if ptitleCont.length > 0
          $('#menu_top').children('.menu-content').after(stickyContent)
        for item in stickyActions
          for child in item.content
            child.appendTo $('.sticky-paction')

    else if $(window).scrollTop() <= limit - offset
      $('#main_nav').removeClass 'sticky'

      if $('#menu_top').find('.sticky-content').length > 0
        for item in stickyActions
          for child in item.content
            child.appendTo item.originalParent
        $('.sticky-content').remove()

$ ->

  handleOpenMenu()
  handleCloseMenu()
  handleResetMenu()
  handleOpenMenuPanel()
  sticker()
