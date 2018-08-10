#= require notifications_center

class WorkbenchNotification
  constructor: (@payload, @owner)->

  show: (fancy=true)->
    @container = $('<div class="notification"></div>')
    link = $("<a href='#{@payload.url}'></a>")
    link.html I18n.t("notifications.#{@payload.message_key}", @payload)
    link.appendTo @container
    close = $("<a class='close-notification' href='#'><span class='fa fa-times'></span></a>")
    close.appendTo @container
    close.click (e)=>
      e.preventDefault()
      @remove()
      false
    @container.prependTo $('.notifications')

    if fancy
      requestAnimationFrame =>
        @container.addClass "new-notification"
      setTimeout =>
        @container.removeClass "new-notification"
      , 500

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
    for notif in @state
      notif.show(false)

  receivedNotification: (payload)->
    console.log({payload})
    console.log("notification url: #{payload.url}")
    console.log("current url: #{document.location.pathname}")
    if document.location.pathname != payload.url
      notif = new WorkbenchNotification(payload, this)
      @pushToState(notif)
      $(".notifications .notification:nth-child(#{@stateMaxSize})").remove()
      $('.notifications .notification').removeClass 'new-notification'
      notif.show()

  pushToState: (notification)->
    @state.shift() while @state.length >= @stateMaxSize
    @state.push notification
    @saveState()

  removeNotification: (notif)->
    @state.splice @state.indexOf(notif), 1
    @saveState()

  saveState: ()->
    bak = []
    for notif in @state
      bak.push notif.dump()
    @notificationCenter.setCookie @channel, JSON.stringify(bak)

  loadState: =>
    @state = []
    bak = @notificationCenter.getCookie @channel
    if bak?
      bak = JSON.parse bak
      for item in bak
        @pushToState new WorkbenchNotification(item, this)

$ ->
  for meta in $('meta[name=current_workbench_notifications_channel]')
    new WorkbenchNotificationsCenter $(meta).attr('content')
