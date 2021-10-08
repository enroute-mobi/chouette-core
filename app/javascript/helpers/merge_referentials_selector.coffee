class MergeReferentialsSelector
  constructor: (container_selector, @formInput)->
    @container = $(container_selector)
    @searchInput = @container.find('.search')
    @loader = @container.find('.loader')
    @results = @container.find('.source-referentials')
    @selected = @container.find('.target')
    @clearGroup = @container.find('.clear-group')
    @clearGroup.toggle(@searchInput.val().length > 0)
    @clearBt = @clearGroup.find('a')
    @searchGroup = @container.find('.search-group')
    @searchBt = @searchGroup.find('a.search')
    @hideLoader()
    @initSortables()
    @performSearch()
    @formInput ||= $('input[name*=referential_ids]')
    @clearBt.click =>
      @clear()
    @searchBt.click =>
      @performSearch()

    @searchInput.on 'keyup', =>
      @searchKeyUp()
    @searchInput.on 'keyup keypress', (e)=>
      keyCode = e.keyCode || e.which
      if keyCode == 13
        e.preventDefault()
        clearTimeout(@searchCoolDown) if @searchCoolDown
        @performSearch()
        false

  selectedIds: ->
    ids = []
    for item in @selected.find("li:not(.remaining-placeholder)")
      ids.push $(item).data().id
    ids

  hideLoader: ->
    @loader.hide()
    @searchGroup.show()
    @searchInput.attr 'readonly', false

  showLoader: ->
    @loader.show()
    @searchGroup.hide()
    @searchInput.attr 'readonly', true

  initSortables: ->
    @container.find(".source-referentials li").draggable
      connectToSortable: ".target"
      placeholder: "placeholder"
      revert: "invalid"
      cancel: ".disabled"
      helper: (event)=>
        target = event.currentTarget
        li = $(target).clone()
        li.width target.clientWidth
        li.height target.clientHeight
        li.css zIndex: 100
        @addDeleteAction(li)
        li

    @container.find(".target").sortable
      axis: "y"
      placeholder: "placeholder"
      start: (event, ui)=>
        $(".target").addClass 'sorting'
      stop: (event, ui)=>
        $(".target").removeClass 'sorting'
      receive: (event, ui)=>
        ui.item.addClass "disabled"
        ui.helper.css "height", ""

      update: (event, ui)=>
        @updateValue()

    @container.find(".target li").each (i, li)=>
      @addDeleteAction($(li))

  addDeleteAction: (container)->
    container.find('a.delete').click (e)=>
      container.addClass "masked"
      @results.find("li[data-id=#{container.data().id}]").removeClass('disabled')
      e.preventDefault()
      setTimeout =>
        container.remove()
        @updateValue()
      , 500
      false

  updateValue: ->
    @formInput.val @selectedIds()
    $(".target .remaining-placeholder").appendTo($(".target"))

  searchKeyUp: ->
    clearTimeout(@searchCoolDown) if @searchCoolDown
    @clearGroup.toggle(@searchInput.val().length > 0)
    @searchCoolDown = setTimeout =>
      @performSearch()
    , 500

  clear: ->
    @searchInput.val ''
    @clearGroup.hide()
    @performSearch()

  performSearch: ->
    search = @searchInput.val()
    unless @url
      @url = @searchInput.data().searchurl
    @showLoader()

    fetch("#{@url}?q=#{search}", {
      credentials: 'same-origin'
    }).then (response) =>
      response.json()
    .then (json) =>
      @results.html ''
      _selected = @selectedIds()
      json.forEach (ref) =>
        li = $("<li data-id='#{ref.id}'><span>#{ref.name}</span><a href='#' class='pull-right delete'><span class='fa fa-times'></a><a href='#' class='pull-right add'><span class='fa fa-arrow-right'></a></li>")
        li.appendTo @results
        li.addClass('disabled') unless _selected.indexOf(ref.id) < 0
        li.find('a.add').click (e)=>
          e.preventDefault()
          clone = li.clone()
          clone.appendTo @container.find(".target")
          @updateValue()
          @addDeleteAction(clone)
          li.addClass "disabled"
          clone.addClass "masked"
          setTimeout =>
            clone.removeClass "masked"
          , 100

          false

      @hideLoader()
      @initSortables()

export default MergeReferentialsSelector
