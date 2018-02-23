$ ->

  stickyActions = []
  ptitleCont = ""
  $(document).on 'page:before-change', ->
    stickyActions = []
    ptitleCont = ""

  $el = $('#main_nav')
    # Opening/closing left-side menu
  $el.find('.openMenu').on 'click', (e) ->
    $(this).parent().addClass 'open'

  $el.find('.closeMenu').on 'click', (e) ->
    $(this).closest('.nav-menu').removeClass 'open'

  # Opening menu panel according to current url
  selectedItem = $el.find('.active')
  selectedItem.closest('.panel-collapse').addClass 'in'
  selectedItem.closest('.panel-title').children('a').attr('aria-expanded') == true

  sticker = () ->
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

  sticker()
  # Sticky behavior
  $(document).on 'scroll', sticker
