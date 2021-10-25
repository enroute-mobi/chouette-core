stickyActions = []
ptitleCont = ""
mainNav = $('#main_nav')

handleResetMenu = ->
  $(document).on 'page:before-change', ->
    stickyActions = []
    ptitleCont = ""

sticker = ->
  # Sticky behavior

  didScroll = ->
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
      mainNav.addClass 'sticky'
      $('body').addClass 'sticky'

      if $('#menu_top').find('.sticky-content').length == 0
        if ptitleCont.length > 0
          $('#menu_top').children('.menu-content').after(stickyContent)
        for item in stickyActions
          for child in item.content
            child.appendTo $('.sticky-paction')

    else if $(window).scrollTop() <= limit - offset
      mainNav.removeClass 'sticky'
      $('body').removeClass 'sticky'

      if $('#menu_top').find('.sticky-content').length > 0
        for item in stickyActions
          for child in item.content
            child.appendTo item.originalParent
        $('.sticky-content').remove()

  $(document).on 'scroll', () =>
    didScroll()

  didScroll()

$ ->

  stickyActions = []
  ptitleCont = ""
  mainNav = $('#main_nav')

  handleResetMenu()
  sticker()
