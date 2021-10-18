#= require notifications_center

class WorkbenchNotification
  constructor: (@payload, @owner)->

  unique_identifier: ->
    @payload.unique_identifier

  update: (payload)->
    return unless payload.progress != @payload.progress || payload.message_key != @payload.message_key
    @payload = payload
    @updateContainer()

    requestAnimationFrame =>
      @container.addClass "updated-notification"
    setTimeout =>
      requestAnimationFrame =>
        @container.removeClass "updated-notification"
    , 500

  show: (fancy=true)->
    @container = $('<div class="notification"></div>')
    @updateContainer()
    close = $("<a class='close-notification' href='#'><span class='fas fa-times'></span></a>")
    close.appendTo @container
    close.click (e)=>
      e.preventDefault()
      if e.shiftKey
        @owner.removeAll()
      else
        @remove()
      false
    @container.prependTo $('.notifications')

    if fancy
      requestAnimationFrame =>
        @container.addClass "new-notification"
      setTimeout =>
        @container.removeClass "new-notification"
      , 500

  updateContainer: ->
    @container.find('.content').remove()
    link = $("<a class='content' href='#{@payload.url}'></a>")
    link.html I18n.t("notifications.#{@payload.message_key}", @payload)
    link.appendTo @container
    progress = @container.find('.progress')
    if @payload.progress
      if progress.length == 0
        progress = $("<div class='progress'></div>")
        progress.prependTo @container
      progress.css width: "#{@payload.progress}%"
      console.log "progress: #{@payload.progress}"
    else
      progress.remove()

  remove: ->
    @container.remove()
    @owner.removeNotification(this)

  dump: ->
    @payload

class WorkbenchNotificationsCenter
  constructor: (@channel)->
    console.log "subscribing to #{@channel}"
    @notificationCenter = new NotificationCenter(@channel, this)
    @stateMaxSize = 5
    @loadState()

  receivedNotification: (payload)->
    if !payload.parent_id
      notif = null
      if payload.unique_identifier
        for existing_notif in @state
          notif = existing_notif if existing_notif.unique_identifier() == payload.unique_identifier

      if notif?
        notif.update payload
        @saveState()
      else
        notif = new WorkbenchNotification(payload, this)
        @pushToState(notif)
        $(".notifications .notification:nth-child(#{@stateMaxSize})").remove()
        $('.notifications .notification').removeClass 'new-notification'
        notif.show()

    for url in payload.urls_to_refresh
      if document.location.pathname == url
        @replaceFragment payload.fragment
        return

  replaceFragment: (fragment)->
    url = document.location.pathname + ".json"
    if document.location.search.length > 0
      url += document.location.search + "&"
    else
      url += "?"
    url += "fragment=#{fragment}"
    fetch(url).then (response)->
      if response.status == 200
        response.json().then (json) =>
          $("##{fragment}").html json.fragment

  pushToState: (notification)->
    @state.shift() while @state.length >= @stateMaxSize
    @state.push notification
    @saveState()

  removeAll: ()->
    @state = []
    @saveState()
    @notificationCenter.reloadState()

  removeNotification: (notif)->
    @state.splice @state.indexOf(notif), 1
    @saveState()
    @notificationCenter.reloadState()

  saveState: ()->
    bak = []
    for notif in @state
      bak.push notif.dump()
    @notificationCenter.setCookie @channel, JSON.stringify(bak)

  loadState: =>
    @state = []
    $('.notifications').html ""
    bak = @notificationCenter.getCookie @channel
    if bak?
      bak = JSON.parse bak
      for item in bak
        notif = new WorkbenchNotification(item, this)
        @pushToState notif
        notif.show(false)

$ ->
  for meta in $('meta[name=current_workbench_notifications_channel]')
    window.notificationCenter = new WorkbenchNotificationsCenter $(meta).attr('content')
